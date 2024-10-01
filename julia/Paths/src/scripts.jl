using DataFrames: DataFrame
using CSV


struct SimulationParams
    maxCost
    pR
    pI
    X
    Y
    scenario
    recoveryLogic
    improvementLogic
    frames
    upf
end

"""
Measures features of the network at a snapshot in time.
"""
struct NetworkMeasurements
    averageTravelCost :: Float64
    totalImprovement :: Float64
    anglesHistogram # Not sure what the type of this is.
end


# struct PathInfo
#     simulationParams :: SimulationParams
#     steps :: Int64
# end


function averageTravelCost(sim :: Paths.Simulation) :: Float64
    n = 0.0
    totalCost = 0.0
    for i in 1:length(sim.locations)
        for j in i+1:length(sim.locations)
            #println(sim.locations[i], sim.locations[j])
            n += 1
            _p, cost = Paths.shortestPath(sim.locations[i].position, sim.locations[j].position, Paths.costs(sim.world))
            totalCost += cost
        end
    end
    return totalCost / n
end


function totalImprovement(sim :: Paths.Simulation) :: Float64
    return sum(sim.world.patches)
end


function viz(sim)
    X = sim.world.X
    Y = sim.world.Y
    discounts = sim.world.maxCost .- costs(sim.world)
    patches = heatmap(1.5:(X + 0.5), 1.5:(Y+0.5), transpose(discounts), axis=([], false), clims=(0, sim.world.maxCost-1), legend=nothing, aspect_ratio=:equal)
    walkers = scatter!([(w.position[1], w.position[2]) for w in sim.walkers], label="", axis=([], false), color="#1f77b4")
    locations = scatter!([(l.position[1], l.position[2]) for l in sim.locations], label="", axis=([], false), color="#ff7f0e")

    # TODO -- add this text
    # sim_ax.text(0, scenario.HEIGHT, animation_describe(upf), color='white', verticalalignment='top')
    # sim_ax.text(0, 0, s.world.describe(), color='white', fontsize=FONT_SIZE)
    # frame_text = sim_ax.text(scenario.WIDTH, 0, "0", color="white", fontsize=FONT_SIZE, horizontalalignment='right')
end



function costsData(;
	X=100,
	Y=100,
	maxCost = 2.0,
	numWalkers = 10,
	numLocations = 10,
	scenario = Paths.RANDOM_FIXED,
    recoveryLogic=Paths.Linear,
    improvementLogic=Paths.Linear,
	maxCosts = [2.0, 4.0, 8.0],
	PIS = [0.01, 0.02, 0.04, 0.08],
	PRS = [0.0001, 0.0002, 0.0004, 0.0008],
	F = 400,
	upf = 100,
	fps=30,
)

folder = "data/$(scenario.description)|$(X)x$(Y)|maxCosts=$(maxCosts)|F=$(F)|upf=$(upf)"

mkpath(folder * "/animations")

datafile = folder * "/data.csv"
@info "saving data to $(datafile)"

	df = DataFrame()

	for maxCost ∈ maxCosts
		for pI ∈ PIS
		    for pR ∈ PRS

		    	animfile = folder * "/animations/$(scenario.description)|$(X)x$(Y)|pI=$(pI)|pR=$(pR)|maxCost=$(maxCost)|UPF=$(upf)|F=$(F).gif"

		    	Random.seed!(2)
		        sim::Simulation = Paths.MakeSimulation(
		            X=X, Y=Y, numWalkers=numWalkers, numLocations=numLocations,
		            patchImprovement=pI, patchRecovery=pR,
		            scenario=scenario, maxCost=maxCost,
                    recoveryLogic=recoveryLogic,
                    improvementLogic=improvementLogic,)

                networkMeasurement = makeNetworkMeasurement(sim)
                

		        averageTravelCosts = [averageTravelCost(sim)]
		        totalImprovements = [totalImprovement(sim)]
		        steps = [0]

		        anim = @animate for f ∈ 1:F
		       		print("\r$(maxCost) $(pI) $(pR) $(f)/$(F)")

		            for u ∈ 1:upf
		                update!(sim)
		            end
		            append!(averageTravelCosts, averageTravelCost(sim))
		            append!(totalImprovements, totalImprovement(sim))
		            append!(steps, f * upf)
		            viz(sim)
                    if (pI == 0.01 && pR >= 0.0008) && f > 50
                        break
                    end
		        end
		        println()
		        gif(anim, animfile, fps = fps)
		        df = vcat(df, DataFrame(travelCosts = averageTravelCosts, improvements=totalImprovements, steps=steps, pI=pI, pR=pR, maxCosts=maxCost))
		    	CSV.write(datafile, df)
		    end
		end
	end
	CSV.write(datafile, df)
end




function animate(
    ;F=1000,
    upf=2,
    X=100,
    Y=100,
    maxCost = 2.0,
    numWalkers = 10,
    numLocations = 10,
    pI = 0.05,
    pR = 0.0005,
    scenario = RANDOM_FIXED,
    improvementLogic = Linear,
    recoveryLogic=Linear,
    # TODO -- maxCost= 2.0,
    fps=30,
    save=true,
)

    filetext = "animations/$(scenario.description)|$(X)x$(Y)|pI=$(pI)|pR=$(pR)|maxCost=$(maxCost)|UPF=$(upf)|F=$(F).gif"


    Random.seed!(2)

    @info "Creating simulation. $(X)x$(Y), $(numWalkers) walkers, $(numLocations) locations, UPF:$(upf), Frames:$(F)";
    @info "Creating simulation. patchImprovement: $(pI) $(improvementLogic), patchRecovery: $(pR) $(recoveryLogic), maxCost: $(maxCost)"
    if save
        @info "Will save to $(filetext)"
    end


    sim::Simulation = MakeSimulation(
        X=X, Y=Y, numWalkers=numWalkers, numLocations=numLocations,
        patchImprovement=pI, patchRecovery=pR,
        scenario=scenario, maxCost=maxCost,
        improvementLogic=improvementLogic,
        recoveryLogic=recoveryLogic,

        )

    anim = @animate for f in 1:F
        print("\r$(f)/$(F)")
        for u in 1:upf
            update!(sim)F
        end
        viz(sim)
    end
    if save
        gif(anim, filetext, fps = fps)
    end
end


function profilemain(
    ;T=1000,
    upf=2,
    X=100,
    Y=100,
    numWalkers = 10,
    numLocations = 10,
    pI = 0.05,
    pR = 0.0005,
    scenario = RANDOM_FIXED,
    # TODO -- maxCost= 2.0,
    fps=30,
)

    @info "Creating simulation. $(X)x$(Y), $(numWalkers) walkers, $(numLocations) locations, UPF:$(upf), Frames:$(T)";
    @info "Creating simulation. patchImprovement: $(pI), patchRecovery: $(pR), maxCost: $(maxCost)"

    sim::Simulation = MakeSimulation(
        X=X, Y=Y, numWalkers=numWalkers, numLocations=numLocations,
        patchImprovement=pI, patchRecovery=pR,
        scenario=scenario, maxCost=maxCost)

    for t in 1:T
        update!(sim)
    end
end
