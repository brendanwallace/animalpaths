using JSON3
using Dates
using Serialization
using Logging
using Plots

import Paths

const FPS = 30

"""
Used for original SVD runs:
    numLocations = 10
    improvementRatios = [75]
    PRs = [0.002, 0.0002]


Used for 4/29/25 SVD runs on Sayak:
    numLocations = 10
    improvementRatios = [75, 50, 25]
    PRs = [0.002, 0.0002]

This is what we used for the talk.
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

    NUM_REPLICAS = 100
    F = 200
    upf = 100
    maxCosts = [2.0]
    patchLogics = [Paths.LINEAR]
    improvementRatios = [75, 50, 25]
    PRs = [0.002, 0.0002]
    COMFORTS = Dict(2.0 => 0.3, 10.0 => 0.5, 5.0 => 0.4)
    searchStrategies = [Paths.KANAI_SUZUKI]
    FOLDER = "data/series/$(seriesName)|$(today())"
    datafile = "$(FOLDER)/data.json"
    mkpath("$(FOLDER)/animations")

    disable_logging(Logging.Info)
    println("saving data to $(datafile)")

    simulationResults::Array{Paths.SimulationResult} = []

    i = 1
    totalI = (length(maxCosts) * length(PRs) * length(improvementRatios)
    	* length(patchLogics) * length(searchStrategies) * NUM_REPLICAS)

    for maxCost ∈ maxCosts
        for ratio ∈ improvementRatios
            for searchStrategy ∈ searchStrategies
                # if searchStrategy == Paths.GRADIENT_WALKER
                # comfort = COMFORTS[maxCost]
                # end
                for pR ∈ PRs
                    for patchLogic ∈ patchLogics
                        pI = pR * ratio






                        for replica ∈ 1:NUM_REPLICAS

                           	settings = Paths.Settings(
                                maxCost=maxCost,
                                scenario=Paths.RANDOM_FIXED,
                                searchStrategy=searchStrategy,
                                patchImprovement=pI,
                                patchRecovery=pR,
                                improvementLogic=patchLogic,
                                recoveryLogic=patchLogic,
                                numSteinerPoints=2,
                                randomSeedWalkers=replica,
                                # comfortWeight=comfort,
                            )

	                        simulationResult = Paths.SimulationResult(settings)
	                        push!(simulationResults, simulationResult)

	                        sim::Paths.Simulation = Paths.MakeSimulation(settings)
	                        push!(simulationResult.snapshots, Paths.takeSnapshot(sim))

	                        for f ∈ 1:F
	                            print("\r$(maxCost)/$(maxCosts) $(pR)/$(PRs) $(ratio)/$(improvementRatios) $(patchLogic) $(i)/$(totalI) $(f)/$(F)")

	                            for u ∈ 1:upf
	                                Paths.update!(sim)
	                            end
	                            push!(simulationResult.snapshots, Paths.takeSnapshot(sim))
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
    # return simulationResults
    open(datafile, "w") do io
        JSON3.write(io, simulationResults)
    end
end

main()