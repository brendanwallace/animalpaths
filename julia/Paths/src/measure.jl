import Base.@kwdef

const FULLY_IMPROVED_THRESHOLD = 0.99

"""
Measures features of the network at a snapshot in time.
"""
struct Snapshot
    averageTravelCost::Float64
    averageTravelLength::Float64
    totalImprovement::Float64
    # How much improvement, counting squares at >=0.99 as 1.0, and others as 0.0.
    thresholdImprovement::Float64
    # How many improvement steps have happened in the simulation.
    steps::Integer
    # The actual network. TBD on how to measure angles or anything like that.
    paths::Array{Path}
    # Weighted histogram of path headings (relative to going straight towards the target)
    weightedHeadings::Array{Tuple{Float64,Float64}}
    avgHeading::Float64
    avgSquareHeading::Float64
    # patches::Array{Float64}
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

function weightedHeadingsRelative(path::Path)::Array{Tuple{Float64,Float64}}
    headings = Array{Tuple{Float64,Float64}}(undef, length(path) - 1)
    target = path[length(path)]
    targetStep = target .- path[i]
    targetAngle = atan(targetStep[2], targetStep[1]) / π
    for i in 1:length(path)-1
        step = path[i+1] .- path[i]
        stepAngle = atan(step[2], step[1]) / π
        # angle of 0.25 above and 0.25 below should count the same
        differenceAngle = abs(stepAngle - targetAngle)
        # there may be a better way to accomplish this but I'm not sure
        differenceAngle = min(2.0 - differenceAngle, differenceAngle)
        headings[i] = (differenceAngle, norm(step))
    end
    return headings
end

@testitem "Test headings histogram" begin
    using Paths, Test

    @test Paths.weightedHeadingsRelative([(0.0, 0.0), (1.0, 0.0)]) == [(0.0, 1.0)]
    @test Paths.weightedHeadingsRelative([(0.0, 0.0), (0.0, 1.0)]) == [(0.0, 1.0)]

    # looks like this:
    #      e
    #      |
    #   s--
    #  distance 1 in direction π/2, then 1 in direction 0
    @test Paths.weightedHeadingsRelative([(0.0, 0.0), (0.0, 1.0), (1.0, 1.0)]) == [(1 / 4, 1.0), (0, 1.0)]
    # Same as above, but going in the negative direction
    @test Paths.weightedHeadingsRelative([(0.0, 0.0), (0.0, -1.0), (-1.0, -1.0)]) == [(1 / 4, 1.0), (0, 1.0)]
    # Same as above, but going in the x direction
    @test Paths.weightedHeadingsRelative([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)]) == [(1 / 4, 1.0), (0, 1.0)]

    @test Paths.weightedHeadingsRelative([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)]) == [(1 / 4, 1.0), (0, 1.0)]
end

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



function snapshot(sim::Paths.Simulation; savepaths=false, saveheadings=false)::Snapshot
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

    weightedHeadings = allWeightedHeadings(paths)
    avgHeading = firstMoment(weightedHeadings)
    avgSquareHeading = secondMoment(weightedHeadings)

    if !savepaths
        paths = []
    end
    if !saveheadings
        weightedHeadings = []
    end


    return Snapshot(
        totalCost / n,
        totalLength / n,
        totalImprovement(sim.world.patches),
        thresholdImprovement(sim.world.patches),
        sim.steps,
        paths,
        weightedHeadings,
        avgHeading,
        avgSquareHeading,
        # deepcopy(sim.world.patches)
    )
end

@testitem "snapshot sanity checks" begin
    # Test defaults
    using Test, Paths
    sim = Paths.MakeSimulation(Paths.Settings(numWalkers=1, X=10, Y=10, numLocations=2))
    @test Paths.snapshot(sim) isa Paths.Snapshot

    grid = Paths.MakeSimulation(Paths.Settings(searchStrategy=Paths.GRID_WALK_NEUMANN, numWalkers=1, X=10, Y=10, numLocations=2))
    @test Paths.snapshot(grid) isa Paths.Snapshot

    hexgrid = Paths.MakeSimulation(Paths.Settings(searchStrategy=Paths.GRID_WALK_NEUMANN, numWalkers=1, X=10, Y=10, numLocations=2))
    @test Paths.snapshot(hexgrid) isa Paths.Snapshot

    directsearch = Paths.MakeSimulation(Paths.Settings(searchStrategy=Paths.DIRECT_SEARCH, numWalkers=1, X=10, Y=10, numLocations=2))
    @test Paths.snapshot(directsearch) isa Paths.Snapshot
end