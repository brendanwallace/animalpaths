mutable struct Simulation
	world :: AbstractWorld
	walkers :: Array{Walker}
	locations :: Array{Location}
	scenario :: AbstractScenario
	patchImprovement :: Float64
	patchRecovery :: Float64
	maxCost :: Float64

	Simulation() = new()
end



function random_pos(sim) Tuple{Float64, Float64}
	return Tuple(rand(2).*[sim.world.X, sim.world.Y].+1)
end


function update!(sim :: Simulation)
	for w in sim.walkers
		update!(w)
	end
	update!(sim.world)
end



# function MakeSimulation(;X=DEFAULT_L, Y=DEFAULT_L, numWalkers = NUM_WALKERS,
# 	numLocations=NUM_LOCATIONS,
# 	patchImprovement = PATCH_IMPROVEMENT, patchRecovery = PATCH_RECOVERY,
# 	scenario = RANDOM_FIXED, maxCost=MAX_COST) :: Simulation

function MakeSimulation(;X, Y, numWalkers, numLocations, patchImprovement,
	patchRecovery, scenario, maxCost) :: Simulation
	
	sim = Simulation()
	sim.world = World(X, Y, sim);
	sim.walkers = scenario.walkers(sim, numWalkers);
	sim.locations = scenario.locations(sim, numLocations);
	sim.scenario = scenario;

	# Options
	sim.patchImprovement = patchImprovement
	sim.patchRecovery = patchRecovery
	sim.maxCost = maxCost

	return sim
end


@testitem "simulation sanity check" begin
	using Paths, Test, Random

	Random.seed!(1)
	sim = Paths.MakeSimulation(numWalkers=1, numLocations=1, X=10, Y=10,
		patchImprovement=0.05, patchRecovery=0.0005,
		scenario=Paths.RANDOM_FIXED, maxCost=2.0)
	@test sim isa Simulation
	for i in 1:2
		# print("\ri$(i)")
		update!(sim)
	end
	@test sim isa Simulation

	Random.seed!(1)
	sim = Paths.MakeSimulation(numWalkers=1, numLocations=1, X=10, Y=10,
		patchImprovement=0.05, patchRecovery=0.0005,
		scenario=Paths.RANDOM_DYNAMIC, maxCost=2.0)
	@test sim isa Simulation
	for i in 1:2
		# print("\ri$(i)")
		update!(sim)
	end
	@test sim isa Simulation
end
