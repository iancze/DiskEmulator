import YAML
config = YAML.load(open("config.yaml"))

# Points at which to create images
parameters = readdlm("parameters_star.dat")

# Go through each of these and plot images, saving with the filename `image_001.out` etc,
# where each index corresponds to the line number in the parameters file.

using DiskJockey.constants
using DiskJockey.model
using DiskJockey.visibilities
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

write_grid("", grid)

# Iterate over rows
for i in 1:size(parameters,1)
    row = parameters[i,:]

    println("processing ", row)

    # Frequency will always be the first parameter
    nu, mass, r_c, T_10, q, logM_gas, ksi, incl, PA = row

    # Write out the Frequency to synthesize at
    lam = cc./(nu * 1e9) * 1e4 # [μm]

    write_lambda([lam], "")

    # Update the parameters
    pars.M_star = mass
    pars.r_c = r_c
    pars.T_10 = T_10
    pars.q = q
    pars.M_gas = 10^logM_gas
    pars.ksi = ksi
    pars.incl = incl
    pars.PA = PA

    # Write the RADMC input files
    write_model(pars, "", grid, species)

    # Perform the synthesis and save it
    (sizeau_desired, sizeau_command) = size_au(config["size_arcsec"], pars.dpc, grid) # [AU]

    tic()
    run(`radmc3d image incl $(pars.incl) posang $(pars.PA) npix $npix loadlambda sizeau $sizeau_command`)
    println("Synthesis runtime")
    toc()

    # Copy image.out to a new filename
    out = @sprintf("image_%3.3i.out", i)
    cp("image.out", "images/" * out, remove_destination=true)
    println("Finished ", pars)


end
