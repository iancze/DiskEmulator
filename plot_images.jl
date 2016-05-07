import YAML
config = YAML.load(open("config.yaml"))

# Points at which to create images
parameters = readdlm("parameters.dat")

parnames = config["emulator"]["parameters"]

npoints = size(parameters, 1)

using DiskJockey.constants
using DiskJockey.model
using DiskJockey.visibilities
using DiskJockey.image
using HDF5

import PyPlot.plt
using LaTeXStrings

cmap = plt[:get_cmap]("plasma")

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

# Figure out how many plots we'll have.
ncols = 8
nrows = ceil(Int, npoints/ncols)

xx = 1.5 * 9
dx = 1.5
yy = (nrows + 1) * 1.5
dy = 1.5

fig, ax = plt[:subplots](nrows=nrows, ncols=ncols, figsize=(xx, yy))

for row=1:nrows
    for col=1:ncols
        iframe = col + (row - 1) * ncols

        if iframe > npoints
          # ax[row, col][:imshow](zeros((im_ny, im_nx)), cmap=cmap, vmin=0, vmax=20, extent=ext, origin="lower")
          continue
        else

          image = @sprintf("image_%3.3i.out", iframe)

          println(row, " ", col, " ", iframe)

          nu, incl = parameters[iframe,:]

          # Load image into SkyImage
          img = imread("images/" * image)
          pars.incl = incl
          skim = imToSky(img, pars.dpc)

          vvmax = maxabs(img.data)
          norm = PyPlot.matplotlib[:colors][:Normalize](0, vvmax)

          # Image needs to be flipped along RA dimension
          ext = (skim.ra[end], skim.ra[1], skim.dec[1], skim.dec[end])

          if col != 1 || row != nrows
              ax[row, col][:xaxis][:set_ticklabels]([])
              ax[row, col][:yaxis][:set_ticklabels]([])
          else
              ax[row, col][:set_xlabel](L"$\Delta \alpha$ ('')")
              ax[row, col][:set_ylabel](L"$\Delta \delta$ ('')")
          end

          #Flip the frame for Sky convention
          frame = flipdim(img.data[:,:,1], 2)

          ax[row, col][:imshow](frame, extent=ext, interpolation="none", origin="lower", cmap=cmap, norm=norm)
        end

    end
end


fig[:subplots_adjust](hspace=0.00, wspace=0.00, top=(yy - 0.5 * dy)/yy, bottom=(0.5 * dy)/yy, left=(0.5 * dx)/xx, right=(xx - 0.5 * dy)/xx)
plt[:savefig]("chmaps_all_params.png", dpi=600)
