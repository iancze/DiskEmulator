import YAML
config = YAML.load(open("config.yaml"))

# Read the array from a text file

# Instead of using a Latin Hypercube, write out parameters in several dimensions, starting from a central point and then doing ranges. 5 points in each sample.

nus = linspace(345.7956, 345.7975, 5)
masses = linspace(0.8, 1.3, 5)
r_cs = linspace(300, 600, 5)
T_10s = linspace(60, 130, 5)
qs = linspace(0.3, 0.7, 5)
logM_gass = linspace(-3, -1.5, 5)
ksis = linspace(0.2, 0.5, 5)
incls = linspace(35, 55, 5)
PAs = linspace(145, 160, 5)

np = 9

total = 5 * np

pars = Array(Float64, (np, total))

parranges = Float64[nus masses r_cs T_10s qs logM_gass ksis incls PAs]

println(parranges)

centers = Int64[3, 3, 3, 3, 3, 3, 3, 3]

colinds = Int64[i for i=1:np]
println(colinds)


for col=1:np
  for row=1:5
    k = (col - 1) * 5 + row

    # insert!(copy(centers)), index, item)
    ind = copy(centers)
    insert!(ind, col, row)

    parsub = Array(Float64, np)

    for (l, pair) in enumerate(zip(ind, colinds))
      parsub[l] = parranges[pair...]
    end

    pars[:,k] = parsub

  end
end

println(size(pars'))
println(pars')

# Now, write this parameter list to disk
writedlm("parameters_star.dat", pars')
