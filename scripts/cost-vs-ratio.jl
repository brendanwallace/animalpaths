using JSON3
using Dates
using Serialization
using Logging
using Plots

import Paths

# Invariant.
patchLogics = [Paths.LINEAR]
seriesName = "cost_vs_ratio"

# Data to save.
SHORTEST_PATHS = false
SAVE_PATHS = false
SAVE_HEADINGS = false
SAVE_PATCHES = true


F = 10
upf = 1000
maxCosts = range(start=1.0, stop=16.0, step=0.25)
improvementRatios = [50.0, 75.0, 100.0, 150.0, 200.0]
PRs = [0.001]
boundaryConditions = [Paths.PERIODIC, Paths.SOLID]
numLocations = [16]
LOCATION_CONFIGURATIONS = [1]
NUM_REPLICAS = 2
numWalkers = 10
searchStrategies = [Paths.KANAI_SUZUKI]
sideLengthFactors = [1] # multiply side lengths and pI by this factor
scenarios = [Paths.RANDOM_DYNAMIC]



# Includes the shared `main` function.
include("runs.jl")



"""

# Separated 10/19/26 in preparation of papers.
# Run generally used for the figures.

F = 100
upf = 100
maxCosts = [2.0, 4.0, 8.0]
improvementRatios = [50.0, 100.0, 200.0]
PRs = [0.001]
boundaryConditions = [Paths.PERIODIC, Paths.SOLID]
numLocations = [16]
LOCATION_CONFIGURATIONS = [1]
NUM_REPLICAS = 2
numWalkers = 10
searchStrategies = [Paths.KANAI_SUZUKI]
sideLengthFactors = [1, 2] # multiply side lengths and pI by this factor
scenarios = [Paths.RANDOM_FIXED, Paths.RANDOM_DYNAMIC, Paths.CENTRAL_PLACE, Paths.WALL_TO_WALL]

"""