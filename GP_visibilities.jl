using GaussianProcesses
using HDF5

# Load the possible parameter combinations

# Points at which to create images
parameters = readdlm("parameters.dat")

drop_out = parameters[end, :]
parameters = parameters[1:end-1, :]

# Column headers
# nu, mass, r_c, T_10, q, logM_gas, ksi, incl, PA = row

d = 2 # dimensions
n = size(parameters, 1) # number of observations

# Load the sampled visibilities from HDF5
fid = h5open("grid_VV_old.hdf5", "r")
reals = read(fid, "real")
imags = read(fid, "imag")
VV = reals + imags .* im # Complex visibility
close(fid)

# Choose our visibility
vis = squeeze(VV[1, :], 1)

# Subtract the mean value
vis_norm = vis .- mean(vis)

vis_drop_out = vis_norm[end]
vis_norm = vis_norm[1:end-1]

# # Plot a histogram of these
# import PyPlot.plt
# using LaTeXStrings
#
# fig = plt[:figure]()
# ax = fig[:gca](projection="3d")
#
# ax[:scatter](parameters[:,1], parameters[:,2], real(vis_norm), color="k")
# ax[:scatter](drop_out[1], drop_out[2], real(vis_drop_out), color="r")
#
# plt[:show]()
# fig[:savefig]("3d_plot.png")
#
# quit()

#Choose mean and covariance function
mZero = MeanZero()                             # Zero mean function

# Log of length scale
# ll = Float64[-3, -1, -0.5, 1, -1, 1, 2, 0, -1]
ll = Float64[-4.0, -0.5]
logSigma = 0.1

kern = SE(ll, logSigma)

# log standard deviation of observation noise (this is optional)
# logObsNoise = -5.
gp = GP(parameters', real(vis_norm), mZero, kern) #, logObsNoise)   # Fit the GP

optimize!(gp; ftol=1e-20)

# nus = linspace(345.7956, 345.7975, 5)
# masses = linspace(0.8, 1.3, 5)
# r_cs = linspace(300, 600, 5)
# T_10s = linspace(60, 130, 5)
# qs = linspace(0.3, 0.7, 5)
# logM_gass = linspace(-3, -1.5, 5)
# ksis = linspace(0.2, 0.5, 5)
# incls = linspace(35, 55, 5)
# PAs = linspace(145, 160, 5)

println()
println("GP mean: ", gp.m)
println("GP kernel: ", gp.k)

x_predict = drop_out

mu, sigma2 = predict(gp, x_predict')
sigma = sqrt(sigma2)

println("mu: $mu, sigma: $sigma")
println("dropout: ", real(vis_drop_out))
