# Two separate comparisons

# How does a given visibility vary with inclination? (fixed nu)
# How does a given visibility vary with nu? (fixed incl)

using DiskJockey.constants
using DiskJockey.model
using DiskJockey.visibilities
using DiskJockey.image
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

nincl = 10
nchan = 10

# Instead of reading in wavelengths from data file, use those we've specified
# Spanning the central 3 chanels of DM Tau, but w/ high resolution.
freqs = linspace(2.3052281389490067e11, 2.3052365978614038e11, nchan)
# Convert from Hz to wavelengths in μm
lams = cc ./freqs * 1e4 # [μm]

# The list of inclinations we want to create
incls = linspace(140., 158., nincl)

# Make a single plot
# Choose a visibility at random
# And plot it's value (real and imag) as we go from inc = 140 to 160

chan_index = 6 # Choose just the first channel, for now (fixed nu)

dvarr = DataVis(config["data_file"], true)
nvis = length(dvarr[1].VV)

fig, ax = plt[:subplots](nrows=2, figsize=(6,6), sharex=true)


# Load all models into memory
mvs = Array(Complex128, (nincl, nvis))

for (i,incl) in enumerate(incls)
    #Load the visibilities corresponding to this model
    model_file = @sprintf("model_%.0f.hdf5", incl)

    mvs[i, :] = DataVis(model_file, true)[chan_index].VV
end

for vis_index in rand(1:nvis, 50)
    vis = mvs[:, vis_index]

    ax[1][:plot](incls, real(vis)/mean(real(vis)), lw=0.2)
    ax[2][:plot](incls, imag(vis)/mean(imag(vis)), lw=0.2)
end

ax[1][:set_ylabel]("real")
ax[2][:set_ylabel]("imag")
ax[2][:set_xlabel]("inclination (degrees)")

fig[:savefig]("visibilities.png")
