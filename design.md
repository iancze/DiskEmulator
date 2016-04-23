# Design

The emulator will work in the following way.

We will consider the calculation of each channel's likelihood independently, and frequency (nu) will be treated like a separate parameter in the calculation. It will include parameters like Mass, r_c, T10, q, log10 M_disk, inclination, position angle, turbulence, and other properties. This will be an 8+ dimensional space. I am reluctant to include distance, since we should know its effect already. But it is a good test to include, I suppose.

What won't be included are positional offsets mu_RA and mu_DEC--these will be handled during the actual sampling phase. Velocity will be taken care of by the velocity interpolation, but this should really be in the ballpark.

Then, we need to come up with an estimate of a bounded space for what works here. I'm not really sure the best way to do this, but either running MCMC on the simplest model possible (isothermal?) might get us to a good estimate. Next, we will need to come up with an estimate of the bounded space... parameter ranges that will span the space. This can be difficult, because we obviously have a limitation to how many parameters we want to sample at the same time, it gets harder and harder to explore higher dimensional spaces. This is why we need some sort of efficient experiment design in this space, and is where orthogonal-array Latin hypercubes come into play. Frequency bounds will span something like the nearest 2 channels, or whatever makes sense in the space corresponding to the model. Because of the way we would fractionally span frequency space, I think we can lump the RADMC runs for adjacent channels together, and synthesize models of the full channels together. This isn't absolutely necessary, but will save some time for the more complex models that require solving vertical temperature gradients, or NLTE, or whatever.

Testing of this design should include projections down into each of the joint 2D spaces (at least) to see how well the collection of points uniformly fills these spaces.

However, say we solve the problem of experiment design and then actually properly span the space efficiently. Then, we want to synthesize models at each of these points and sample them at the baseline locations. This means for each channel, we will have a large collection of models. This could potentially be a very large dataset, but I hope that it would at least come in under a Gb... I would need to spec this out. Presumably we should store the visibilities in order of increasing `q` distance, rather than just random `u` and `v` locations as they are currently stored. The great aspect of this model is that this is the only stage where calculation by `RADMC-3D` is actually required.

Design of this space should be taken care of via Latin Hypercubes. Python packages exist to create these: https://pypi.python.org/pypi/pynolh, Cioppa
http://pydoc.net/Python/mcerp/0.9.2/mcerp.lhd/


Then, we would run PCA on the full collection of models in this space, hopefully collapsing the visibilities down into something like 5-10 eigenspectra to represent 99% or whatever of the space.

Then, we would train a GP on these eigenspectra weights to replicate the behavior of the visibilities. This is an optimization step that will probably take some time, but the good news is that we can optimize each channel completely independently and is something we could probably put to a cluster, but *hopefully* this only takes a short time, since it scales with (number of eigenvectors * number of simulation models). If we can keep the number of eigenvectors to ~5 or 10 and the number of simulation models to ~500 - 1000, then I think this shouldn't be too bad. My expectation is that the middle channels, where the source is actually resolved, will require the largest numbers of eigenspectra, whereas the edge channels (essentially just point sources) will require very, very few eigenspectra.

Once trained, we now are in the fortunate position of actually being able to assess the true accuracy of the emulator. We can draw random points from the parameter space, compute emulated visibilities and true visibilities. We can spot check a bunch of points and hopefully find that they matter very little in the computation of a lnprob relative to our data set. If this isn't the case, then we will need to go back to the previous step and either increase the number of simulation runs or the number of eigenvectors. Moreover, at this stage we can also assess the *uncertainty introduced by the emulator*, since we can actually sample the range of the predicted visibilities via our emulator distribution delivered.

Frequency modes. So, we could simply treat this as the ability for the emulator to interpolate in the frequency space, which for one channel independently should only correspond to a velocity shift. However, the exciting new possibility for the emulator to actually average (or integrate) visibilities across the channel width, corresponding to the true effect of the telescope. So, the question is, what happens when we do an integral of `I(u,v,nu)` across some range of nu. See Rasmussen and Williams, section 9.8.

If we have modeled the function with a squared exponential (which I certainly plan to do), then the integral of f can be computed analytically. Because we are actually writing `Inu` as the summation of a bunch of GPs, I *think* we can still do this as the sum of integrals of each GP independently, however I'm not sure if the covariance between GP weights complicates this. My expectation is that this should be possible, although it may require some work. Anyway, we can probably just integrate the mean function to start and then compare this to what would happen if we treated the emulator uncertainty.

Then, we go and sample the probability distribution for all channels together, but for each channel using a separate emulator. Because we will probably have different numbers of eigenspectra per channel, this probably will take a different amount of time per channel, but my hope is that this is so fast overall that we should be able to sample all channels in the same process quickly.

## Discrepancy model

Eventually, it will be interesting to include a discrepancy model basis in the visibility domain. My idea is that some sort of Gaussian basis might help a lot.
