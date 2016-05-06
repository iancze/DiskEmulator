# using JudithExcalibur

nincl = 10
nchan = 10

# The list of inclinations we want to create
incls = linspace(140., 158., nincl)

# Go through each of these and plot images, saving with the filename `image_140.out` where 140 is the inclination.

using DiskJockey.constants
using DiskJockey.model
using DiskJockey.visibilities
using HDF5

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

# Instead of reading in wavelengths from data file, use those we've specified
# Spanning the central 3 chanels of DM Tau, but w/ high resolution.
freqs = linspace(2.3052281389490067e11, 2.3052365978614038e11, nchan)
# Convert from Hz to wavelengths in μm
lams = cc ./freqs * 1e4 # [μm]

# Doppler shift the dataset wavelength according to the velocity in the parameter file
beta = vel/c_kms # relativistic Doppler formula
shift_lams =  lams .* sqrt((1. - beta) / (1. + beta)) # [microns]

# Now write this out
write_lambda(shift_lams, "")

for incl in incls
    # For each inclination, update pars.incl
    pars.incl = incl

    # Write the RADMC input files
    write_model(pars, "", grid, species)

    # Perform the synthesis and save it
    (sizeau_desired, sizeau_command) = size_au(config["size_arcsec"], pars.dpc, grid) # [AU]

    tic()
    run(`radmc3d image incl $(pars.incl) posang $(pars.PA) npix $npix loadlambda sizeau $sizeau_command`)
    println("Synthesis runtime")
    toc()

    # Copy image.out to a new filename
    out = @sprintf("image_%.0f.out", pars.incl)
    cp("image.out", out)
    println("Finished ", pars)

end
