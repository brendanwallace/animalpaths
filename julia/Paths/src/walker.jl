const ARRIVAL_DISTANCE = 1.0
const WALKER_SPEED = 1.0


mutable struct SearchWalker <: Walker
	simulation :: Simulation
	target :: Union{Location, Nothing}
	position :: Tuple{Float64, Float64}
	path :: Array{Node}
	SearchWalker(simulation, target, position) = new(simulation, target, position, [])
end


function update!(walker :: SearchWalker)
	if walker.target isa Nothing
		walker.simulation.scenario.newTarget!(walker)
		walker.path, _cost = shortestPath(walker.position, walker.target.position, costs(walker.simulation.world))
	end

	traveled = 0.0
	while traveled < WALKER_SPEED
		if length(walker.path) == 0
			@debug "walker ran out of path at $(walker.position) without arriving at $(walker.target.position)."
			prevTarget = walker.target

			walker.simulation.scenario.newTarget!(walker)
			walker.path, _cost = shortestPath(walker.position, walker.target.position, costs(walker.simulation.world))
			# TODO – could require that we actually hit a new target, and then we could keep walking.
			break
		end
		nextNode = walker.path[1]
		# This should be in the middle of the correct square.
		# TODO -- this should put more weight into the face which has lower cost if
		# we're walking right along an edge.
		improvePosition = (nextNode.position .+ walker.position) ./ 2
		nextEdgeLength = norm(nextNode.position .- walker.position)
		facesToImprove = faces(improvePosition)
		if (traveled + nextEdgeLength) < WALKER_SPEED
			walker.position = nextNode.position
			for face in facesToImprove
				improvePatch!(walker.simulation.world, face, nextEdgeLength / length(facesToImprove))
			end
			traveled += nextEdgeLength
			popfirst!(walker.path)
		else
			distanceToTravel = WALKER_SPEED - traveled
			walker.position = walker.position .+ (distanceToTravel .* (nextNode.position .- walker.position))
			for face in facesToImprove
				improvePatch!(walker.simulation.world, face, distanceToTravel / length(facesToImprove))
			end
			traveled = WALKER_SPEED
		end
	end
end


mutable struct DirectWalker <: Walker
	simulation :: Simulation
	target :: Union{Location, Nothing}
	position :: Tuple{Float64, Float64}
end


function update!(walker :: DirectWalker)
	if walker.target isa Nothing
		walker.target = rand(walker.simulation.locations)
	end
	arrived = norm(walker.position - walker.target.position) <= ARRIVAL_DISTANCE
	if arrived
		walker.target = rand(walker.simulation.locations)
	else
		direction = normalize(walker.target.position - walker.position)
		walker.position += direction * WALKER_SPEED
		improvePatch!(walker.simulation.world, walker.position)
	end
end
