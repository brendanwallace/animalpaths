

"""
Main method for running simulations, measuring
costs and saving to json.
"""
function main()
    # if length(ARGS) < 1
    #     throw("supply a name for this series by running `julia $(PROGRAM_FILE) [series name]`")
    # else
    #     seriesName = ARGS[1]
    # end

    # COMFORTS = Dict(2.0 => 0.3, 10.0 => 0.5, 5.0 => 0.4)
    FOLDER = "data/$(seriesName)|$(today())"
    datafile = "$(FOLDER)/data.json"
    mkpath("$(FOLDER)")



    # debug_logger = ConsoleLogger(stderr, Logging.Debug);
    # global_logger(debug_logger);
    disable_logging(Logging.Info)
    println("saving data to $(datafile)")

    simulationResults::Array{Paths.SimulationResult} = []

    i = 1
    totalI = (length(maxCosts) * length(PRs) * length(improvementRatios) * length(numLocations)
              * length(patchLogics) * length(boundaryConditions) * NUM_REPLICAS * length(LOCATION_CONFIGURATIONS)
              * length(searchStrategies)
              )

    for searchStrategy ∈ searchStrategies
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
                                            searchStrategy=searchStrategy,
                                            patchImprovement=pI,
                                            patchRecovery=pR,
                                            improvementLogic=patchLogic,
                                            recoveryLogic=patchLogic,
                                            numSteinerPoints=2,
                                            randomSeedWalkers=replica,
                                            randomSeedLocations=locationSeed,
                                            boundaryConditions=boundaryCondition,
                                            numLocations=nLocations,
                                            numWalkers=numWalkers,
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
                                                    savepaths=SAVE_PATHS, # don't default to saving these.
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
    end
    # return simulationResults
    open(datafile, "w") do io
        JSON3.write(io, simulationResults)
    end
end

main()