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

# Doppler shift the dataset wavelength according to the velocity in the parameter file
beta = vel/c_kms # relativistic Doppler formula
shift_lams =  lams .* sqrt((1. - beta) / (1. + beta)) # [microns]

vels = c_kms * (shift_lams .- lam0)/lam0


# The list of inclinations we want to create
incls = linspace(140., 158., nincl)

# Create a series of subplots
xx = 1.5 * (1 + nchan)
dx = 1.5
yy = (1 + nincl) * 1.5
dy = 1.5

fig, ax = plt[:subplots](nrows=nincl, ncols=nchan, figsize=(xx, yy))

for (row,incl) in enumerate(incls)
    image = @sprintf("image_%.0f.out", incl)

    # Load image into SkyImage
    img = imread(image)
    pars.incl = incl
    skim = imToSky(img, pars.dpc)

    vvmax = maxabs(img.data)
    norm = PyPlot.matplotlib[:colors][:Normalize](0, vvmax)

    # Image needs to be flipped along RA dimension
    ext = (skim.ra[end], skim.ra[1], skim.dec[1], skim.dec[end])

    for col=1:nchan
        iframe = col

        if col != 1 || row != nincl
            ax[row, col][:xaxis][:set_ticklabels]([])
            ax[row, col][:yaxis][:set_ticklabels]([])
        else
            ax[row, col][:set_xlabel](L"$\Delta \alpha$ ('')")
            ax[row, col][:set_ylabel](L"$\Delta \delta$ ('')")
        end


        #Flip the frame for Sky convention
        frame = flipdim(img.data[:,:,iframe], 2)

        im = ax[row, col][:imshow](frame, extent=ext, interpolation="none", origin="lower", cmap=cmap, norm=norm)

        # if iframe==1
        #     # Plot the colorbar
        #     cax = fig[:add_axes]([(xx - 0.35 * dx)/xx, (yy - 1.5 * dy)/yy, (0.1 * dx)/xx, dy/yy])
        #     cbar = fig[:colorbar](mappable=im, cax=cax)
        #
        #     cbar[:ax][:tick_params](labelsize=6)
        #     fig[:text](0.99, (yy - 1.7 * dy)/yy, "Jy/beam", size=8, ha="right")
        # end

        ax[row, col][:annotate](@sprintf("%.1f", vels[iframe]), (0.1, 0.8), xycoords="axes fraction", size=8)

    end
end

fig[:subplots_adjust](hspace=0.00, wspace=0.00, top=(yy - 0.5 * dy)/yy, bottom=(0.5 * dy)/yy, left=(0.5 * dx)/xx, right=(xx - 0.5 * dy)/xx)
plt[:savefig]("channel_maps.png", dpi=600)
