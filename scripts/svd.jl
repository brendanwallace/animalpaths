using JSON3
using Dates
using Serialization
using Logging
using Plots

import Paths

# Invariant.
patchLogics = [Paths.LINEAR]
searchStrategies = [Paths.GRID_WALK_MOORE, Paths.GRID_WALK_NEUMANN]
seriesName = "SVD"

# Data to save.
SHORTEST_PATHS = false
SAVE_PATHS = false
SAVE_HEADINGS = false
SAVE_PATCHES = true


# 7/21 SVD run with other search strategies
F = 20
upf = 1000
maxCosts = [2.0, 8.0]
improvementRatios = [100]
PRs = [0.001]
boundaryConditions = [Paths.SOLID]
numLocations = [10, 20]
LOCATION_CONFIGURATIONS = [1, 2]
NUM_REPLICAS = 64

# Includes the shared `main` function.
include("runs.jl")



"""
# 7/4 SVD run
F = 20
upf = 1000
maxCosts = [2.0]
improvementRatios = [100]
PRs = [0.001]
boundaryConditions = [Paths.PERIODIC, Paths.SOLID]
numLocations = [10, 20]
LOCATION_CONFIGURATIONS = [1, 2, 3, 4]
NUM_REPLICAS = 128

6/23 SVD run
    F = 200
    upf = 100
    maxCosts = [2.0]
    improvementRatios = [100]
    PRs = [0.001]
    boundaryConditions = [PERIODIC, SOLID]
    numLocations = [10, 20]
    NUM_LOCATION_CONFIGURATIONS = 4
    NUM_REPLICAS = 64

6/18 SVD run
    maxCosts = [2.0, 8.0]
    improvementRatios = [100]
    PRs = [0.001]
    boundaryConditions = [PERIODIC, SOLID]
    numLocations = [10, 20]
    NUM_LOCATION_CONFIGURATIONS = 4
    NUM_REPLICAS = 64

Used for original SVD runs:
    numLocations = 10
    improvementRatios = [75]
    PRs = [0.002, 0.0002]

Used for 4/29/25 SVD runs on Sayak:
    numLocations = 10
    improvementRatios = [75, 50, 25]
    PRs = [0.002, 0.0002]

Wide SVD

    maxCosts = [2.0, 8.0]
    improvementRatios = [50, 100]
    PRs = [0.002, 0.0002]
    boundaryConditions = [PERIODIC, SOLID]
    numLocations = [10, 20]
    NUM_LOCATION_CONFIGURATIONS = 4
    NUM_REPLICAS = 8
"""
