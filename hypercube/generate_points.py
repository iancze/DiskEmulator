import pynolh
import numpy as np

dim = 2

conf, remove = pynolh.CONF[dim]
nolh = pynolh.nolh(conf, remove)

print(nolh)

minimum, maximum = np.min(nolh), np.max(nolh)
print("minimum", minimum)
print("maximum", maximum)

if dim > 7:
    # Standardize to interval 0 to 1
    nolh += 0.25

# Write this array to disk
np.savetxt("array.dat", nolh)

if __name__=="__main__":

    from corner import corner

    fig = corner(nolh, plot_contours=False, plot_datapoints=True, plot_density=False, data_kwargs={"alpha":1.0, "color":"k", "mec":"k"})
    fig.savefig("design.png")
