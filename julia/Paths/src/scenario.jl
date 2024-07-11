# Might make this concrete in this file
struct Scenario <: AbstractScenario
    locations #:: (simulation::Simulation) -> Array{Location}
    walkers #:: (simulation::Simulation) -> Array{Walker}
    newTarget! #:: (simulation::Simulation, walker::Walker)
end


function randomLocations(simulation::Simulation, numLocations) :: Array{Location}
	return [Location(random_pos(simulation)) for i in 1:numLocations]
end

function randomWalkers(simulation::Simulation, numWalkers) :: Array{Walker}
	return [SearchWalker(simulation, nothing, random_pos(simulation)) for i in 1:numWalkers]
end


RANDOM_FIXED::Scenario = Scenario(randomLocations, randomWalkers, 
	# newRandomTarget
	(walker) -> walker.target = rand(walker.simulation.locations);
)


function newRandomDynamicLocation(walker)

	prevTarget = walker.target
	if !(prevTarget isa Nothing)
		delete!(walker.simulation.locations, prevTarget)
	end
	walker.target = Location(random_pos(walker.simulation))
	push!(walker.simulation.locations, walker.target)
end

RANDOM_DYNAMIC::Scenario = Scenario((_x, _y)->[], randomWalkers, newRandomDynamicLocation)
