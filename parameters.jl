import YAML
config = YAML.load(open("config.yaml"))

# Read the array from a text file

# 2D matrix of shape (npoints, nparams) spanning from [0,1]
nolh = readdlm("hypercube/array.dat")

# Map the ranges of parameters in config.yaml onto the Latin Hypercube

# Read emulator, and convert this to a 1D array of starting points, and
# a 1D array of widths

parnames = config["emulator"]["parameters"]

starting = Float64[config["emulator"]["ranges"][parname][1] for parname in parnames]
deltas = Float64[(config["emulator"]["ranges"][parname][2] - config["emulator"]["ranges"][parname][1]) for parname in parnames]

# Broadcast these to a proper 2D array
# Do this addition and broadcasting in column-major
shifts = (nolh' .* deltas)
parameters = shifts .+ starting

# Shift back to row-major
parameters = parameters'

# Now, write this parameter list to disk
writedlm("parameters.dat", parameters)
