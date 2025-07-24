import Base.@kwdef

const FULLY_IMPROVED_THRESHOLD = 0.99

"""
Measures features of the network at a snapshot in time.
"""
@kwdef mutable struct Snapshot
    averageTravelCost::Float64 = 0.0
    averageTravelLength::Float64 = 0.0
    totalImprovement::Float64 = 0.0
    # How much improvement, counting squares at >=0.99 as 1.0, and others as 0.0.
    thresholdImprovement::Float64 = 0.0
    # How many improvement steps have happened in the simulation.
    steps::Integer = 0
    # The actual network. TBD on how to measure angles or anything like that.
    paths::Array{Path} = []
    # Weighted histogram of path headings (relative to going straight towards the target)
    weightedHeadings::Array{Tuple{Float64,Float64}} = []
    avgHeading::Float64 = 0.0
    avgSquareHeading::Float64 = 0.0
    patches::Array{Float64} = []

    # anglesHistogram # Not sure what the type of this is.
end


"""
Measurements of a single simulation.
"""
struct SimulationResult
    settings::Settings
    snapshots::Array{Snapshot}

    SimulationResult(settings::Settings) = new(settings, [])
end


"""
Routes to the appropriate search algorithm given `settings`
"""
function shortestPath(
    source::Position, target::Position, world::World, settings::Settings)::Tuple{Path,Float64}

    if settings.searchStrategy ∈ [KANAI_SUZUKI, DIRECT_SEARCH, GRADIENT_WALKER]
        # use exact search for these.
        return shortestPathKanaiSuzuki(source, target, costs(world), numSteinerPoints=settings.numSteinerPoints)
    elseif settings.searchStrategy ∈ [GRID_WALK_4, GRID_WALK_HEX, GRID_WALK_HEX_PLUS, GRID_WALK_8]

        return gridSearch(source, target, world, settings.searchStrategy)

    else
        throw("no shortest path method found for $(settings.searchStrategy)")
    end
end


function pathLength(path::Path)::Float64
    l = 0.0
    for i in 1:(length(path)-1)
        l += norm(path[i] .- path[i+1])
    end
    return l
end


@testitem "Test for pathLength" begin
    using Paths, Test

    @test Paths.pathLength([(0.0, 0.0), (1.0, 0.0)]) == 1.0
    @test Paths.pathLength([(0.0, 0.0), (0.0, 5.0), (5.0, 5.0)]) == 10.0
    @test Paths.pathLength([(5.0, 5.0), (0.0, 5.0), (0.0, 0.0)]) == 10.0
end


function totalImprovement(patches::Array{Float64})::Float64
    return sum(patches)
end

"""
Counts up patches that are improved to at least a specified threshold. 
"""
function thresholdImprovement(patches)::Float64
    return sum(map(x ->
            if x >= FULLY_IMPROVED_THRESHOLD
                1.0
            else
                0.0
            end, patches))
end


@testitem "Test for thresholdImprovement" begin
    using Paths, Test

    @test Paths.thresholdImprovement([1.001]) == 1.0
    @test Paths.thresholdImprovement([0.98, 0.99, 0.991]) == 2.0
end

# function weightedHeadingsRelative(path::Path)::Array{Tuple{Float64,Float64}}
#     headings = Array{Tuple{Float64,Float64}}(undef, length(path) - 1)
#     target = path[length(path)]
#     targetStep = target .- path[1]
#     targetAngle = atan(targetStep[2], targetStep[1]) / π
#     for i in 1:length(path)-1
#         step = path[i+1] .- path[i]
#         stepAngle = atan(step[2], step[1]) / π
#         # angle of 0.25 above and 0.25 below should count the same
#         differenceAngle = abs(stepAngle - targetAngle)
#         # there may be a better way to accomplish this but I'm not sure
#         differenceAngle = min(2.0 - differenceAngle, differenceAngle)
#         headings[i] = (differenceAngle, norm(step))
#     end
#     return headings
# end

# @testitem "Test headings histogram" begin
#     using Paths, Test

#     @test Paths.weightedHeadingsRelative([(0.0, 0.0), (1.0, 0.0)]) == [(0.0, 1.0)]
#     @test Paths.weightedHeadingsRelative([(0.0, 0.0), (0.0, 1.0)]) == [(0.0, 1.0)]

#     # looks like this:
#     #      e
#     #      |
#     #   s--
#     #  distance 1 in direction π/2, then 1 in direction 0
#     @test Paths.weightedHeadingsRelative([(0.0, 0.0), (0.0, 1.0), (1.0, 1.0)]) == [(1 / 4, 1.0), (0, 1.0)]
#     # Same as above, but going in the negative direction
#     @test Paths.weightedHeadingsRelative([(0.0, 0.0), (0.0, -1.0), (-1.0, -1.0)]) == [(1 / 4, 1.0), (0, 1.0)]
#     # Same as above, but going in the x direction
#     @test Paths.weightedHeadingsRelative([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)]) == [(1 / 4, 1.0), (0, 1.0)]

#     @test Paths.weightedHeadingsRelative([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)]) == [(1 / 4, 1.0), (0, 1.0)]
# end

function weightedHeadings(path::Paths.Path)::Array{Tuple{Float64,Float64}}
    headings = Array{Tuple{Float64,Float64}}(undef, length(path) - 1)
    target = path[length(path)]
    targetStep = target .- path[1]
    targetAngle = atan(targetStep[2], targetStep[1]) # between -1pi and 1pi
    for i in 1:length(path)-1
        step = path[i+1] .- path[i]
        stepAngle = atan(step[2], step[1]) # between -1pi and 1pi
        differenceAngle = min(abs(stepAngle - targetAngle), abs(stepAngle + targetAngle))
        headings[i] = (differenceAngle, norm(step))
    end
    return headings
end

function allWeightedHeadings(paths::Array{Path})::Array{Tuple{Float64,Float64}}
    return reduce(vcat, [weightedHeadings(path) for path in paths])
end


function firstMoment(valWeightPairs::Array{Tuple{Float64,Float64}})::Float64
    totalVal, totalWeight = 0.0, 0.0
    for (val, weight) ∈ valWeightPairs
        totalVal += val * weight
        totalWeight += weight
    end
    return totalVal / totalWeight
end

@testitem "test firstMoment" begin
    using Paths, Test
    @test Paths.firstMoment([(1.0, 100.0)]) == 1.0
    @test Paths.firstMoment([(100.0, 1.0)]) == 100.0
    @test Paths.firstMoment([(10.0, 1.0), (0.0, 1.0)]) == 5.0
    @test Paths.firstMoment([(1.0, 5.0), (0.0, 5.0)]) == 0.5
end

function secondMoment(valWeightPairs::Array{Tuple{Float64,Float64}})::Float64
    totalVal, totalWeight = 0.0, 0.0
    for (val, weight) ∈ valWeightPairs
        totalVal += val * val * weight
        totalWeight += weight
    end
    return totalVal / totalWeight
end


@testitem "test secondMoment" begin
    using Paths, Test
    @test Paths.secondMoment([(1.0, 100.0)]) == 1.0
    @test Paths.secondMoment([(100.0, 1.0)]) == 10000.0
    @test Paths.secondMoment([(10.0, 1.0), (0.0, 1.0)]) == 50.0
    @test Paths.secondMoment([(1.0, 5.0), (0.0, 5.0)]) == 0.5
end
# function anglesInPath(path::Path)::



function takeSnapshot(sim::Paths.Simulation;
    shortestpaths=false, savepaths=false, saveheadings=false, savepatches=true,
    )::Snapshot

    snapshot = Snapshot()

    if shortestpaths
        n = 0.0
        totalCost = 0.0
        totalLength = 0.0
        paths::Array{Path} = []
        for i in 1:length(sim.locations)
            for j in i+1:length(sim.locations)
                #println(sim.locations[i], sim.locations[j])
                n += 1
                p, cost = Paths.shortestPath(
                    sim.locations[i].position, sim.locations[j].position, sim.world, sim.settings)
                totalCost += cost
                totalLength += pathLength(p)
                push!(paths, p)
            end
        end

        snapshot.averageTravelCost = totalCost / n
        snapshot.averageTravelLength = totalLength / n


        if savepaths
            snapshot.paths = paths
        end
        if saveheadings
            snapshot.weightedHeadings = allWeightedHeadings(paths)
            snapshot.avgHeading = firstMoment(snapshot.weightedHeadings)
            snapshot.avgSquareHeading = secondMoment(snapshot.weightedHeadings)
        end
    end

    snapshot.totalImprovement = totalImprovement(sim.world.patches)
    snapshot.steps = sim.steps

    if savepatches
        snapshot.patches = deepcopy(sim.world.patches)
    end

    return snapshot
end

@testitem "snapshot sanity checks" begin
    # Test defaults
    using Test, Paths
    sim = Paths.MakeSimulation(Paths.Settings(numWalkers=1, X=10, Y=10, numLocations=2))
    @test Paths.takeSnapshot(sim) isa Paths.Snapshot

    grid = Paths.MakeSimulation(Paths.Settings(searchStrategy=Paths.GRID_WALK_4, numWalkers=1, X=10, Y=10, numLocations=2))
    @test Paths.takeSnapshot(grid) isa Paths.Snapshot

    hexgrid = Paths.MakeSimulation(Paths.Settings(searchStrategy=Paths.GRID_WALK_4, numWalkers=1, X=10, Y=10, numLocations=2))
    @test Paths.takeSnapshot(hexgrid) isa Paths.Snapshot

    directsearch = Paths.MakeSimulation(Paths.Settings(searchStrategy=Paths.DIRECT_SEARCH, numWalkers=1, X=10, Y=10, numLocations=2))
    @test Paths.takeSnapshot(directsearch) isa Paths.Snapshot
end