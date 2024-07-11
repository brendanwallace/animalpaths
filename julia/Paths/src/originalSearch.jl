
include("search.jl")

function addFaces!(node)
	δ = 0.001
	pos = node.position
	faces = unique([Int64.(floor.(pos .+ delta)) for delta in [(δ, 0), (0, δ), (-δ, 0), (0, -δ)]])
	for face in faces
		push!(node.faces, face)
	end
end


function populateNeigbors!(nodes, node)
	
end


# Runs the original search while constructing the graph on the fly.
function originalSearch!(nodes :: Dictionary{Position, Node},
	source::Node, target::Node, costs::Matrix{Float64}) :: LinkedList{Edge}

	pq = PriorityQueue{Item, Float64}()
	visited = Set{Node}()

	enqueue!(pq, Item(source, nil(Edge), 0.0), 0.0)

	# pop the top element and add its neighbors
	while !isempty(pq)
		item = dequeue!(pq)
		# println("popping: ", item)
		if !in(item.node, visited)
			if item.node == target
				return item.path
			end

			push!(visited, item.node)
			populateNeighbors!(nodes, item.node)
			for edge in item.node.neighbors
				cost = item.pathCost + edge.cost
				enqueue!(pq, Item(edge.node, cons(edge, item.path), cost), (cost + heuristic(edge.node.position, target.position)))
			end
		end
	end

	# This means we couldn't find a path.
	return nil(Edge)
end