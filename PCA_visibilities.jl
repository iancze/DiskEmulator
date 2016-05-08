import YAML
config = YAML.load(open("config.yaml"))

using DiskJockey.constants
using DiskJockey.model
using DiskJockey.visibilities
using DiskJockey.image
using DiskJockey.gridding
using MultivariateStats
using HDF5

dv = DataVis(config["data_file"], true)[5]

# Conjugation is necessary for the SMA and ALMA
visibilities.conj!(dv)

qq = get_qq(dv)

# Find the indices that sort these in increasing order
ind = sortperm(qq)
qq = qq[ind]
uu = dv.uu[ind]
vv = dv.vv[ind]

# Points at which to create images
parameters = readdlm("parameters.dat")
npoints = size(parameters, 1)

fid = h5open("grid_VV.hdf5", "r")
# Load the sampled visibilities from HDF5
reals = read(fid, "real")
imags = read(fid, "imag")
VV = reals + imags .* im # Complex visibility

close(fid)

nvis = size(reals, 1)

println("Dimensions of input matrix ", size(reals))

# suppose Xtr and Xte are training and testing data matrix,
# with each observation in a column

# Need to do the reals and imaginaries separately, since MultivariateStats does not work w/ Complex128

mean_estimate = mean(reals, 2)
std_estimate = std(reals, 2)

norm_reals = (reals .- mean_estimate) ./ std_estimate
# norm_reals = reals .- mean_estimate

# train a PCA model
M = fit(PCA, norm_reals; mean=0, pratio=0.999)

dump(M)

eigen = projection(M)

println("projection", size(eigen))

ncomp = outdim(M)


# a (npoints, ncomp) matrix
weights = Array(Float64, (npoints, ncomp))

# Calculate the weights that lead to reconstruction of the visibilities
for i=1:npoints
  for j=1:ncomp
    weights[i,j] = sum(reals[:,i] .* eigen[:,j])
  end
end

# Now try reconstructing the spectra
reconstructed_reals = Array(Float64, (nvis, npoints))
for i=1:npoints
  reconstructed_reals[:,i] = std_estimate .* ((eigen * squeeze(weights[i,:], 1)) .+ mean_estimate)
  # reconstructed_reals[:,i] = (eigen * squeeze(weights[i,:], 1)) .+ mean_estimate
end

ms=0.1

# Compare the reconstructed spectra vs the reals.
import PyPlot.plt
using LaTeXStrings

fig, ax = plt[:subplots](nrows=3, figsize=(10, 6), sharex=true)

for i=1:3
  ax[1][:plot](qq, reals[:,i], ".", ms=ms)
  ax[2][:plot](qq, reconstructed_reals[:,i], ".", ms=ms)
  ax[3][:plot](qq, reals[:,i] - reconstructed_reals[:,i], ".", ms=ms)
end

ax[1][:set_xlabel](L"$qq\quad k\lambda$")
ax[1][:grid]()
ax[2][:grid]()
ax[3][:grid]()

plt[:savefig]("visibilities_reconstructed.png", dpi=600)


fig, ax = plt[:subplots](nrows=3, figsize=(10, 6), sharex=true)

ax[1][:plot](qq, mean_estimate, ".", ms=ms)
ax[2][:plot](qq, std_estimate, ".", ms=ms)

for i=1:size(eigen, 2)
  ax[3][:plot](qq, eigen[:,i], ".", ms=ms)
end

ax[3][:set_xlabel](L"$qq\quad k\lambda$")

ax[1][:grid]()
ax[2][:grid]()
ax[3][:grid]()

ax[1][:set_ylabel]("Mean")
ax[2][:set_ylabel]("Std")
ax[3][:set_ylabel]("Real")

plt[:savefig]("visibilities_PCA_real.png", dpi=600)
