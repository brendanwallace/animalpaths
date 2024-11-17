using JSON3
using Dates
using Serialization
using Logging
using Plots

import Paths

const FPS = 30



"""
This is the main method for running a bunch of simulations and measuring
costs and saving them to json.
"""
function main()

    F = 500
    upf = 100
    maxCosts = [2.0, 10.0]
    patchLogics = [Paths.LOGISTIC]
    improvementRatios = [25, 50, 75]
    PRs = [0.002]
    COMFORTS = Dict(2.0 => 0.3, 10.0 => 0.5)
    searchStrategies = [Paths.DIRECT_SEARCH]
    FOLDER = "data/series/series|$(today())|F=$(F)|searchAlgorithms2"
    datafile = "$(FOLDER)/data.json"
    mkpath("$(FOLDER)/animations")

    disable_logging(Logging.Info)
    println("saving data to $(datafile)")

    simulationResults::Array{Paths.SimulationResult} = []

    i = 1
    totalI = length(maxCosts) * length(PRs) * length(improvementRatios) * length(patchLogics) * length(searchStrategies)

    for searchStrategy ∈ searchStrategies
        for maxCost ∈ maxCosts
            comfort = COMFORTS[maxCost]
            for pR ∈ PRs
                for ratio ∈ improvementRatios
                    for patchLogic ∈ patchLogics
                        pI = pR * ratio

                        animfile = "$(FOLDER)/animations/$(searchStrategy)|$(patchLogic)|ratio$(ratio)|pR$(pR)|maxCost$(maxCost).gif"



                        settings = Paths.Settings(
                            maxCost=maxCost,
                            scenario=Paths.RANDOM_FIXED,
                            searchStrategy=searchStrategy,
                            patchImprovement=pI,
                            patchRecovery=pR,
                            improvementLogic=patchLogic,
                            recoveryLogic=patchLogic,
                            comfortWeight=comfort,
                        )

                        simulationResult = Paths.SimulationResult(settings)
                        push!(simulationResults, simulationResult)

                        sim::Paths.Simulation = Paths.MakeSimulation(settings)
                        push!(simulationResult.snapshots, Paths.snapshot(sim))

                        anim = @animate for f ∈ 1:F
                            print("\r$(maxCost)/$(maxCosts) $(pR)/$(PRs) $(ratio)/$(improvementRatios) $(patchLogic) $(i)/$(totalI) $(f)/$(F)")

                            for _ ∈ 1:upf
                                Paths.update!(sim)
                            end
                            push!(simulationResult.snapshots, Paths.snapshot(sim))
                            Paths.viz(sim)
                            # if (pI == 0.01 && pR >= 0.0008) && f > 50
                            #     break
                            # end
                        end

                        gif(anim, animfile, fps=FPS)

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
    # return simulationResults
    open(datafile, "w") do io
        JSON3.write(io, simulationResults)
    end
end

main()