import YAML
config = YAML.load(open("config.yaml"))

using DiskJockey.constants
using DiskJockey.model
using DiskJockey.visibilities
using DiskJockey.image
using DiskJockey.gridding
using HDF5

import PyPlot.plt
using LaTeXStrings

# Points at which to create images
parameters = readdlm("parameters_star.dat")

dv = DataVis(config["data_file"], true)[5]

# Conjugation is necessary for the SMA and ALMA
visibilities.conj!(dv)

qq = get_qq(dv)

# Find the indices that sort these in increasing order
ind = sortperm(qq)

qq = qq[ind]
uu = dv.uu[ind]
vv = dv.vv[ind]


fid = h5open("grid_VV.hdf5", "r")
# Load the sampled visibilities from HDF5
reals = read(fid, "real")
imags = read(fid, "imag")
VV = reals + imags .* im # Complex visibility

close(fid)

npoints = size(VV, 2)

mean_vis = mean(VV, 2)

# See how the real and imaginary values of the visibility change over the full range.

# Subtract the value

# Normalize the change in visibility from -1 to 1

# Write function that takes in a range, that shows the min to max of that value.
index = Float64[i for i=1:5]

lw = 0.3

function plot_range(range, fname)

  # index this subset of parameters
  pars = parameters[range, :]
  # print(pars)

  # select this subset of visibilities
  VV_sub = VV[:,range]

  println(size(VV_sub))

  fig, ax = plt[:subplots](nrows=3, figsize=(10, 9), sharex=true)

  # for i in rand(1:npoints, 1000)
  for i=1:npoints
    vis = squeeze(VV_sub[i, :], 1)

    ax[1][:plot](index, abs(vis), lw=lw)
    ax[2][:plot](index, real(vis), lw=lw)
    ax[3][:plot](index, imag(vis), lw=lw)
  end

  ax[3][:set_xlabel]("index")

  ax[1][:set_ylabel]("Mod")
  ax[2][:set_ylabel]("Real")
  ax[3][:set_ylabel]("Imag")

  plt[:savefig](fname, dpi=600)


end

plot_range(1:5, "visibilities_nu.png")
plot_range(6:10, "visibilities_mass.png")
plot_range(11:15, "visibilities_r_c.png")
plot_range(16:20, "visibilities_T_10.png")
plot_range(21:25, "visibilities_q.png")
plot_range(26:30, "visibilities_logM_gas.png")
plot_range(31:35, "visibilities_ksi.png")
plot_range(36:40, "visibilities_incl.png")
plot_range(41:45, "visibilities_PA.png")

quit()
