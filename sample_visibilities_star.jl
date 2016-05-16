import YAML
config = YAML.load(open("config.yaml"))

# Points at which to create images
parameters = readdlm("parameters_star.dat")

npars = size(parameters, 1)


# Go through each of these and plot images, saving with the filename `image_001.out` etc,
# where each index corresponds to the line number in the parameters file.

using DiskJockey.constants
using DiskJockey.model
using DiskJockey.visibilities
using DiskJockey.image
using DiskJockey.gridding
using HDF5

grd = config["grid"]
grid = Grid(grd)

# Load the parameters file from the configuration setting, and make this an object.
pars = convert_dict(config["parameters"], config["model"])
vel = pars.vel # [km/s]
npix = config["npix"] # number of pixels
species = config["species"]
transition = config["transition"]
lam0 = lam0s[species*transition]
model = config["model"]

# Load the visibilities and sort
dv = DataVis(config["data_file"], true)[5]
# Conjugation is necessary for the SMA and ALMA
visibilities.conj!(dv)

qq = get_qq(dv)
# Find the indices that sort these in increasing order
ind = sortperm(qq)
qq = qq[ind]
uu = dv.uu[ind]
vv = dv.vv[ind]
nvis = length(qq)

VV = Array(Complex128, (nvis, npars))

# Iterate over rows
for i in 1:size(parameters,1)
    row = parameters[i,:]
    println("processing ", row)

    # Frequency will always be the first parameter
    nu, mass, r_c, T_10, q, logM_gas, ksi, incl, PA = row

    # Update the parameters
    pars.M_star = mass
    pars.r_c = r_c
    pars.T_10 = T_10
    pars.q = q
    pars.M_gas = 10^logM_gas
    pars.ksi = ksi
    pars.incl = incl
    pars.PA = PA

    # Read in the image
    image = @sprintf("image_%3.3i.out", i)
    im = imread("images/" * image)
    skim = imToSky(im, pars.dpc)
    corrfun!(skim) # alpha = 1.0

    # Determine dRA and dDEC from the image and distance
    dRA = abs(skim.ra[2] - skim.ra[1])/2. # [arcsec] the half-size of a pixel

    # FFT the image channel
    vis_fft = transform(skim)

    # Interpolate the `vis_fft` to the same uu,vv locations as our dataset
    # In the same order as the sorted qq vector
    for j=1:nvis
        VV[j,i] = interpolate_uv(uu[j], vv[j], vis_fft)
    end

end

# write to a file

fid = h5open("grid_VV.hdf5", "w")
fid["uu"] = uu
fid["vv"] = vv
fid["real"] = real(VV)
fid["imag"] = imag(VV)
close(fid)
