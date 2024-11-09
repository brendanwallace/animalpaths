import Base.@kwdef

using JSON3
using Dates
using Serialization

const FPS = 30


"""
Measures features of the network at a snapshot in time.
"""
struct Snapshot
    averageTravelCost::Float64
    averageTravelLength::Float64
    totalImprovement::Float64
    # How many improvement steps have happened in the simulation.
    steps::Integer
    # The actual network. TBD on how to measure angles or anything like that.
    paths::Array{Path}
    # Weighted histogram of path headings (relative to going straight towards the target)
    # weightedHeadings::Array{Tuple{Float64,Float64}}
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


function totalImprovement(sim::Simulation)::Float64
    return sum(sim.world.patches)
end

function weightedHeadings(path::Path)::Array{Tuple{Float64,Float64}}
    headings = Array{Tuple{Float64,Float64}}(undef, length(path) - 1)
    target = path[length(path)]
    for i in 1:length(path)-1
        step = path[i+1] .- path[i]
        stepAngle = atan(step[2], step[1]) / π
        targetStep = target .- path[i]
        targetAngle = atan(targetStep[2], targetStep[1]) / π
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

    @test Paths.weightedHeadings([(0.0, 0.0), (1.0, 0.0)]) == [(0.0, 1.0)]
    @test Paths.weightedHeadings([(0.0, 0.0), (0.0, 1.0)]) == [(0.0, 1.0)]

    # looks like this:
    #      e
    #      |
    #   s--
    #  distance 1 in direction π/2, then 1 in direction 0
    @test Paths.weightedHeadings([(0.0, 0.0), (0.0, 1.0), (1.0, 1.0)]) == [(1 / 4, 1.0), (0, 1.0)]
    # Same as above, but going in the negative direction
    @test Paths.weightedHeadings([(0.0, 0.0), (0.0, -1.0), (-1.0, -1.0)]) == [(1 / 4, 1.0), (0, 1.0)]
    # Same as above, but going in the x direction
    @test Paths.weightedHeadings([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)]) == [(1 / 4, 1.0), (0, 1.0)]

    @test Paths.weightedHeadings([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)]) == [(1 / 4, 1.0), (0, 1.0)]
end

# function anglesInPath(path::Path)::



function snapshot(sim::Paths.Simulation)::Snapshot
    n = 0.0
    totalCost = 0.0
    totalLength = 0.0
    paths::Array{Path} = []
    for i in 1:length(sim.locations)
        for j in i+1:length(sim.locations)
            #println(sim.locations[i], sim.locations[j])
            n += 1
            p, cost = Paths.shortestPathKanaiSuzuki(
                sim.locations[i].position, sim.locations[j].position, Paths.costs(sim.world))
            totalCost += cost
            totalLength += pathLength(p)
            push!(paths, p)
        end
    end

    # weightedHeadings = weightedHeadings(paths)

    return Snapshot(
        totalCost / n,
        totalLength / n,
        totalImprovement(sim),
        sim.steps,
        paths,
        # deepcopy(sim.world.patches)
    )
end



"""
This is the main method for running a bunch of simulations and measuring
costs and saving them to json.
"""
function runSeries(;
    F=400,
    upf=100,
    maxCosts=[1.5, 2.0, 4.0, 8.0],
    patchLogics=[LINEAR, LOGISTIC, SATURATING],
    improvementRatios=[50, 75, 100, 150, 200],
    PRS=[0.0001, 0.0002, 0.0004],
    searchStrategy=KANAI_SUZUKI,)
    #::Array{SimulationResult}
    FOLDER = "data/series|$(searchStrategy)|$(patchLogics)|$(today())"
    datafile = "$(FOLDER)/data.json"
    mkpath("$(FOLDER)/animations")

    @info "saving data to $(datafile)"

    simulationResults::Array{SimulationResult} = []

    for maxCost ∈ maxCosts
        for pR ∈ PRS
            for improvementRatio ∈ improvementRatios
                for patchLogic ∈ patchLogics
                    pI = pR * improvementRatio

                    animfile = "$(FOLDER)/animations/$(patchLogic)|pI$(pI)|pR$(pR)|maxCost$(maxCost).gif"

                    settings = Settings(
                        maxCost=maxCost,
                        scenario=RANDOM_FIXED,
                        searchStrategy=searchStrategy,
                        patchImprovement=pI,
                        patchRecovery=pR,
                        improvementLogic=patchLogic,
                        recoveryLogic=patchLogic,
                    )

                    simulationResult = SimulationResult(settings)
                    push!(simulationResults, simulationResult)

                    sim::Simulation = Paths.MakeSimulation(settings)
                    push!(simulationResult.snapshots, snapshot(sim))

                    anim = @animate for f ∈ 1:F
                        print("\r$(patchLogic) $(maxCost) $(pI) $(pR) $(f)/$(F)")

                        for _ ∈ 1:upf
                            update!(sim)
                        end
                        push!(simulationResult.snapshots, snapshot(sim))
                        viz(sim)
                        # if (pI == 0.01 && pR >= 0.0008) && f > 50
                        #     break
                        # end
                    end

                    println()
                    gif(anim, animfile, fps=FPS)

                    # This writes out the intermediate data every run (I think).
                    serialize(datafile, simulationResults)
                    open(datafile, "w") do io
                        JSON3.write(io, simulationResults)
                    end
                end
            end
        end
    end
    # return simulationResults
    open(datafile, "w") do io
        JSON3.write(io, simulationResults)
    end
end
