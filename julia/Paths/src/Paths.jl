module Paths

using Dates: now
using Plots
using Random
using Test, TestItems

export update!, Simulation, Settings, Scenario #RANDOM_FIXED, RANDOM_DYNAMIC
export Node, Edge, shortestPathKanaiSuzuki
export animate

include("util.jl")
include("settings.jl")
include("simulation.jl")
include("search.jl")
include("world.jl")
include("walker.jl")
include("setup.jl")
include("measure.jl")
include("visualize.jl")

# const DEFAULT_L = 100::Int
# const NUM_LOCATIONS = 10
# const NUM_WALKERS = 10
# const PATCH_IMPROVEMENT = 0.05
# const PATCH_RECOVERY = 0.0003
# const MAX_COST = 2.0
# const DEFAULT_FPS = 20
# const DEFAULT_UPF = 2


@testitem "Simulation sanity checks" begin
    # Test defaults
    using Test, Paths
    sim = Paths.MakeSimulation(Paths.Settings(numWalkers=1, X=10, Y=10, numLocations=2))
    @test sim isa Paths.Simulation
    Paths.update!(sim)
    @test sim isa Paths.Simulation

    grid = Paths.MakeSimulation(Paths.Settings(searchStrategy=Paths.GRID_WALK, numWalkers=1, X=10, Y=10, numLocations=2))
    Paths.update!(grid)
    @test grid isa Paths.Simulation


    hexgrid = Paths.MakeSimulation(Paths.Settings(searchStrategy=Paths.GRID_WALK, numWalkers=1, gridType=Paths.HEX_WORLD, X=10, Y=10, numLocations=2))
    Paths.update!(hexgrid)
    @test grid isa Paths.Simulation
end


end # module Paths
