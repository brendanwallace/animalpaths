"""
For each analyses we want to look at a low, medium and high version of most
parameters, and then pick one of the other parameters to blow up (look at
a wide range of values) to make a nice graph.

cost-angle: maxCost
optimality: improvement ratio
SVD: number of random seeds (I guess?)

Some parameters never really change.
Number of walkers is just 10.
Patch logic is linear.
Search strategy is default KANAI_SUZUKI.

"""

patchLogics = [Paths.LINEAR]
numWalkers = 10

searchStrategies = [Paths.KANAI_SUZUKI]
upf = 1000
F = 20

maxCosts = [1.5, 2.0, 8.0]
improvementRatios = [5, 10, 20]
PRs = [0.0005, 0.001, 0.002]

boundaryConditions = [Paths.PERIODIC, Paths.SOLID]
numLocations = [8, 16, 32]
LOCATION_CONFIGURATIONS = [1, 2]

