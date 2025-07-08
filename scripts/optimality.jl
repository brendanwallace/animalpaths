using JSON3
using Dates
using Serialization
using Logging
using Plots

import Paths

# Invariant.
patchLogics = [Paths.LINEAR]
searchStrategies = [Paths.KANAI_SUZUKI]

boundaryConditions = [Paths.SOLID, Paths.PERIODIC]
seriesName = "optimality"


# Data to save.
# Optimality needs to compute the shortest paths, but not save the actual paths.
SHORTEST_PATHS = true
SAVE_PATHS = false
SAVE_HEADINGS = false
SAVE_PATCHES = true


# 7/8 Run to look at optimality vs time
NUM_REPLICAS = 4
LOCATION_CONFIGURATIONS = [1, 2]
numLocations = [10]
F = 100
upf = 100
maxCosts = [2.0, 8.0]
improvementRatios = [50.0, 100.0, 150.0, 200.0]
PRs = [0.001]
boundaryConditions = [Paths.SOLID]

include("runs.jl")