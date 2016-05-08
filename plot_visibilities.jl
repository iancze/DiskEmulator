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

fig, ax = plt[:subplots](nrows=3, figsize=(10, 9), sharex=true)

ms=0.1

for i=1:npoints
  vis = VV[:,i]
  ax[1][:plot](qq, abs(vis./mean_vis), ".", ms=ms)
  ax[2][:plot](qq, real(vis./mean_vis), ".", ms=ms)
  ax[3][:plot](qq, imag(vis./mean_vis), ".", ms=ms)
end

ax[3][:set_xlabel](L"$qq\quad k\lambda$")

ax[1][:grid]()
ax[2][:grid]()
ax[3][:grid]()

ax[1][:set_ylabel]("Mod")
ax[2][:set_ylabel]("Real")
ax[3][:set_ylabel]("Imag")

plt[:savefig]("visibilities.png", dpi=600)
