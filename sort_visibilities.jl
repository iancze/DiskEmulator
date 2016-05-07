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
VV = dv.VV[ind]

fig, ax = plt[:subplots](nrows=3, figsize=(10, 9), sharex=true)

ax[1][:plot](qq, abs(VV), "k.")
ax[2][:plot](qq, real(VV), "k.")
ax[3][:plot](qq, imag(VV), "k.")

ax[3][:set_xlabel](L"$qq\quad k\lambda$")

ax[1][:set_ylabel]("Mod")
ax[2][:set_ylabel]("Real")
ax[3][:set_ylabel]("Imag")

plt[:savefig]("sorted_visibilities.png", dpi=600)
