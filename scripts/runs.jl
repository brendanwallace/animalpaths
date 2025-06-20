using JSON3
using Dates
using Serialization
using Logging
using Plots

import Paths

"""
6/20 optimality run
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

This is what we used for the talk.

Angles analysis:

    maxCosts = [1.25, 1.5, 2.0, 3.0, 5.0, 9.0, 17.0, 33.0, 65.0]
    improvementRatios = [75]
    PRs = [0.002]


Wide SVD

    maxCosts = [2.0, 8.0]
    improvementRatios = [50, 100]
    PRs = [0.002, 0.0002]
    boundaryConditions = [PERIODIC, SOLID]
    numLocations = [10, 20]
    NUM_LOCATION_CONFIGURATIONS = 4
    NUM_REPLICAS = 8
"""


"""
This is the main method for running a bunch of simulations and measuring
costs and saving them to json.
"""
function main()
    if length(ARGS) < 1
        throw("supply a name for this series by running `julia $(PROGRAM_FILE) [series name]`")
    else
        seriesName = ARGS[1]
    end

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
    patchLogics = [Paths.LINEAR]
    numLocations = [10, 20] # numLocations = [20, 10]
    # COMFORTS = Dict(2.0 => 0.3, 10.0 => 0.5, 5.0 => 0.4)
    searchStrategies = [Paths.KANAI_SUZUKI]
    FOLDER = "data/series/$(seriesName)|$(today())"
    datafile = "$(FOLDER)/data.json"
    mkpath("$(FOLDER)")

    # What data to save

    SHORTEST_PATHS = true
    SAVE_PATHS = false
    SAVE_HEADINGS = false
    SAVE_PATCHES = true

    # debug_logger = ConsoleLogger(stderr, Logging.Debug);
    # global_logger(debug_logger);
    disable_logging(Logging.Info)
    println("saving data to $(datafile)")

    simulationResults::Array{Paths.SimulationResult} = []

    i = 1
    totalI = (length(maxCosts) * length(PRs) * length(improvementRatios) * length(numLocations)
              * length(patchLogics) * length(boundaryConditions) * NUM_REPLICAS * length(LOCATION_CONFIGURATIONS))

    for maxCost ∈ maxCosts
        for ratio ∈ improvementRatios
            for boundaryCondition ∈ boundaryConditions
                # if searchStrategy == Paths.GRADIENT_WALKER
                # comfort = COMFORTS[maxCost]
                # end
                for pR ∈ PRs
                    for patchLogic ∈ patchLogics
                        pI = pR * ratio

                        for nLocations ∈ numLocations

                            for locationSeed ∈ LOCATION_CONFIGURATIONS


                                for replica ∈ 1:NUM_REPLICAS

                                    settings = Paths.Settings(
                                        maxCost=maxCost,
                                        scenario=Paths.RANDOM_FIXED,
                                        # searchStrategy=searchStrategy,
                                        patchImprovement=pI,
                                        patchRecovery=pR,
                                        improvementLogic=patchLogic,
                                        recoveryLogic=patchLogic,
                                        numSteinerPoints=2,
                                        randomSeedWalkers=replica,
                                        randomSeedLocations=locationSeed,
                                        boundaryConditions=boundaryCondition,
                                        numLocations=nLocations,
                                        # comfortWeight=comfort,
                                    )

                                    simulationResult = Paths.SimulationResult(settings)
                                    push!(simulationResults, simulationResult)

                                    sim::Paths.Simulation = Paths.MakeSimulation(settings)
                                    push!(simulationResult.snapshots, Paths.takeSnapshot(sim))

                                    for f ∈ 1:F
                                        print("\r$(nLocations)/$(numLocations) $(boundaryCondition)/$(boundaryConditions) $(maxCost)/$(maxCosts) $(pR)/$(PRs) $(ratio)/$(improvementRatios) $(patchLogic) $(i)/$(totalI) $(f)/$(F)")

                                        for u ∈ 1:upf
                                            Paths.update!(sim)
                                        end

                                        # We should always save all the information for the final snapshot.
                                        if f == F
                                            push!(simulationResult.snapshots, Paths.takeSnapshot(sim,
                                                shortestpaths=true,
                                                savepaths=true,
                                                saveheadings=true,
                                                savepatches=true,
                                            ))
                                        else
                                            push!(simulationResult.snapshots, Paths.takeSnapshot(sim,
                                                shortestpaths=SHORTEST_PATHS,
                                                savepaths=SAVE_PATHS,
                                                saveheadings=SAVE_HEADINGS,
                                                savepatches=SAVE_PATCHES,
                                            ))
                                        end

                                    end

                                    # This writes out the intermediate data every run (I think).
                                    serialize(datafile, simulationResults)
                                    open(datafile, "w") do io
                                        JSON3.write(io, simulationResults)
                                    end
                                    i += 1
                                end
                            end
                        end
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

main()