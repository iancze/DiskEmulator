using DiskJockey.constants
using DiskJockey.model
using DiskJockey.visibilities
using DiskJockey.image
using DiskJockey.gridding
using HDF5

import PyPlot.plt
using LaTeXStrings

cmap = plt[:get_cmap]("plasma")

import YAML
config = YAML.load(open("config.yaml"))

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

# The list of inclinations we want to create
nincl = 10
incls = linspace(140., 158., nincl)

nchan = 10

# Read the parameters from the config file
pars = convert_dict(config["parameters"], config["model"])


# For *this purpose only*, read in the flagged data in addition to the unflagged data
# so that we can export a model for these otherwise flagged visibilities
dvarr = DataVis(config["data_file"], true)
# Do this as we do in `mach_three.jl`
for dset in dvarr
    # Conjugation is necessary for the SMA and ALMA
    visibilities.conj!(dset) # Swap UV convention
end

# Stick with the baselines contained in the first channel.
dv = dvarr[1]

for incl in incls
    pars.incl = incl
    image = @sprintf("image_%.0f.out", incl)
    im = imread(image)
    skim = imToSky(im, pars.dpc)
    corrfun!(skim) # alpha = 1.0

    # Determine dRA and dDEC from the image and distance
    dRA = abs(skim.ra[2] - skim.ra[1])/2. # [arcsec] the half-size of a pixel
    println("dRA is ", dRA, " arcsec")

    mvarr = Array(DataVis, nchan)



    for i=1:nchan

        # FFT the appropriate image channel
        vis_fft = transform(skim, i)

        # Interpolate the `vis_fft` to the same locations as the DataSet
        mvis = ModelVis(dv, vis_fft)

        # Apply the phase correction here, since there are fewer data points
        phase_shift!(mvis, pars.mu_RA + dRA, pars.mu_DEC - dRA)

        dvis = visibilities.ModelVis2DataVis(mvis)
        mvarr[i] = dvis

        # Now swap the model and residual visibilities back to ALMA/SMA convetion
        visibilities.conj!(mvarr[i])

    end

    model_file = @sprintf("model_%.0f.hdf5", incl)

    visibilities.write(mvarr, model_file)

end
