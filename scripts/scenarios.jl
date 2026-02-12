using JSON3
using Dates
using Serialization
using Logging
using Plots

import Paths

# Invariant.
patchLogics = [Paths.LINEAR]
seriesName = "scenarios"

# Data to save.
SHORTEST_PATHS = false
SAVE_PATHS = false
SAVE_HEADINGS = false
SAVE_PATCHES = true


F = 100
upf = 1000
maxCosts = [2.0, 8.0]
improvementRatios = [100.0, 200.0, 400.0]
PRs = [0.001]
boundaryConditions = [Paths.PERIODIC]
numLocations = [8]
LOCATION_CONFIGURATIONS = [1]
NUM_REPLICAS = 2
numWalkers = 10
searchStrategies = [Paths.KANAI_SUZUKI]
sideLengthFactors = [1, 2] # multiply side lengths and pI by this factor
scenarios = [Paths.RANDOM_DYNAMIC, Paths.CENTRAL_PLACE, Paths.WALL_TO_WALL]



# Includes the shared `main` function.
include("runs.jl")

