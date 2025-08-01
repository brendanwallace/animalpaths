using JSON3
using Dates
using Serialization
using Logging
using Plots

import Paths

# Invariant.
patchLogics = [Paths.LINEAR]
numWalkers = 10

# costs-angles doesn't really make sense with periodic boundaries.
boundaryConditions = [Paths.SOLID]
seriesName = "cost-angles-2"


# What data to save.
# Costs-angles needs to save all of this.
SHORTEST_PATHS = true
SAVE_PATHS = false # <-- might not want to save this actually.
SAVE_HEADINGS = true
SAVE_PATCHES = true





# 8/1 costs run
searchStrategies = [Paths.KANAI_SUZUKI]
upf = 1000
F = 20
maxCosts = [1.25, 1.5, 2.0, 3.0, 5.0, 9.0, 17.0, 33.0, 65.0]
improvementRatios = [100]
PRs = [0.001]
boundaryConditions = [Paths.SOLID]
numLocations = [10, 20]
NUM_REPLICAS = 4
LOCATION_CONFIGURATIONS = [2]



include("runs.jl")


"""


# 7/29 costs run
searchStrategies = [Paths.KANAI_SUZUKI]
upf = 1000
F = 20
maxCosts = [1.25, 1.5, 2.0, 3.0, 5.0, 9.0, 17.0, 33.0, 65.0]
improvementRatios = [100]
PRs = [0.001]
boundaryConditions = [Paths.SOLID]
numLocations = [10, 20]
NUM_REPLICAS = 4
LOCATION_CONFIGURATIONS = [1, 2]


# 7/3 costs run
F = 20
maxCosts = [1.25, 1.5, 2.0, 3.0, 5.0, 9.0, 17.0, 33.0, 65.0]
improvementRatios = [100]
PRs = [0.001]
boundaryConditions = [Paths.SOLID]
numLocations = [10, 20]
NUM_REPLICAS = 4
LOCATION_CONFIGURATIONS = [1, 2]
searchStrategies = [Paths.GRID_WALK_8, Paths.GRID_WALK_4]


# 7/21 costs run
upf = 1000
F = 20
maxCosts = [1.25, 1.5, 2.0, 3.0, 5.0, 9.0, 17.0, 33.0, 65.0]
improvementRatios = [100]
PRs = [0.001]
numLocations = [10, 20]
NUM_REPLICAS = 4
LOCATION_CONFIGURATIONS = [1, 2]
searchStrategies = [Paths.GRID_WALK_8, Paths.GRID_WALK_4]




Angles analysis:

    maxCosts = [1.25, 1.5, 2.0, 3.0, 5.0, 9.0, 17.0, 33.0, 65.0]
    improvementRatios = [75]
    PRs = [0.002]
"""