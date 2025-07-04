using JSON3
using Dates
using Serialization
using Logging
using Plots

import Paths

# Invariant.
patchLogics = [Paths.LINEAR]
searchStrategies = [Paths.KANAI_SUZUKI]

# costs-angles doesn't really make sense with periodic boundaries.
boundaryConditions = [Paths.SOLID]
seriesName = "optimality"


# Data to save.
# Optimality needs to compute the shortest paths, but not save the actual paths.
SHORTEST_PATHS = true
SAVE_PATHS = false
SAVE_HEADINGS = false
SAVE_PATCHES = true


# 6/20 optimality run.
# *****NOTE***** this ran all weekend and didn't finish by Tuesday.
#                 was at ~ 200/1200
NUM_REPLICAS = 8
LOCATION_CONFIGURATIONS = [1, 2]
F = 50
upf = 100
maxCosts = [2.0, 8.0]
improvementRatios = [
    10.0, 20.0, 30.0, 40.0, 50.0, 60.0,
    70.0, 80.0, 90.0, 100.0, 110.0, 120.0,
    130.0, 140.0, 150.0, 160.0, 170.0, 180.0, 190.0, 200.0]
PRs = [0.001]
boundaryConditions = [Paths.SOLID]

include("runs.jl")