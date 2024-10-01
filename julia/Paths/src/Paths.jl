module Paths

using Dates: now
using Plots
using Random
using Test, TestItems

export update!, Simulation, RANDOM_FIXED, RANDOM_DYNAMIC
export Node, Edge, shortestPath

include("common.jl")
include("search.jl")
include("world.jl")
include("simulation.jl")
include("scenario.jl")
include("walker.jl")
include("scripts.jl")

# const DEFAULT_L = 100::Int
# const NUM_LOCATIONS = 10
# const NUM_WALKERS = 10
# const PATCH_IMPROVEMENT = 0.05
# const PATCH_RECOVERY = 0.0003
# const MAX_COST = 2.0
# const DEFAULT_FPS = 20
# const DEFAULT_UPF = 2



end # module Paths
