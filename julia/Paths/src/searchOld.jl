using DataStructures
using TestItems
using Test


const Position = Tuple{Float64, Float64}
const GridPosition = Tuple{Int64, Int64}

# This is the bottom-left corner of the square face.
const Face = GridPosition

abstract type _Edge end


struct Node
	position :: Position
	neighbors :: Vector{_Edge}
	faces :: Vector{Face}
end

Node(pos) = Node(pos, [], [])


# This lets us do deep equality testing by default.
# Otherwise == just sees that the array pointers are different and calls the
# structs different.
Base.:(==)(x::Node, y::Node) = x.position == y.position && 
	x.neighbors == y.neighbors && x.faces == y.faces


struct Edge <: _Edge
	node :: Node
	cost :: Float64
	isOriginal :: Bool
	# faces :: Tuple{Face, Face}
	Edge(node, cost) = new(node, cost, true)
	Edge(node, cost, isOriginal) = new(node, cost, isOriginal)
end

Base.show(io::IO, e::Edge) = print(io, "->$(e.node.position), $(e.isOriginal), $(e.cost)") # $(e.faces),


# # This is probably not necessary anymore.
Base.:(==)(x::Edge, y::Edge) = (
	(x.node.position == y.node.position &&
	# ((x.faces == y.faces) || (x.faces == reverse(y.faces))) &&
	x.isOriginal == y.isOriginal &&
	x.cost == y.cost))


struct Item
	node::Node
	path::LinkedList{Edge}
	pathCost::Float64
end


function astar(source, target)::LinkedList{Edge}

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
			for edge in item.node.neighbors
				cost = item.pathCost + edge.cost
				enqueue!(pq, Item(edge.node, cons(edge, item.path), cost), cost)
			end
		end
	end

	# This means we couldn't find a path.
	# TODO – I'm not sure that this is how you deal with parametric typing
	return nil(Edge)
end


# @testitem "Test for astar" begin
# 	using Paths
# 	using Test
# 	using DataStructures

n1 = Node((1, 1))
e1 = Edge(n1, 10.0)
e2 = Edge(n1, 15.0)
n2 = Node((2, 2))
push!(n2.neighbors, e1)
push!(n2.neighbors, e2)


@test astar(Node((1, 1)), Node((2, 2))) == nil(Edge)
@test astar(n2, n1) == list(e1)

e3 = Edge(n2, 1.0)
e4 = Edge(n1, 20.0)
n3 = Node((3.0, 3.0), [e3, e4], [])

@test astar(n3, n1) == list(e1, e3)
# # end




# Safe way to access cost for a face on the grid.
function costAt(costs, face::Face)
	x, y = face
	X, Y = size(costs)
	if x >= 1 && y >= 1 && x <= X && y <= Y
		return costs[x, y]
	else
		return Inf
	end
end

function constructOriginalGraph(costs::Matrix{Float64}) Dict{Position, Node}
	X, Y = size(costs)
	nodes = Dict{Position, Node}()
	nodesByFace = Dict{Face, Vector{Node}}()

	# Construct the original nodes
	for x = 1:X+1
		for y = 1:Y+1
			position :: Position = Float64.((x, y))
			nodes[position] = Node(position)
		end
	end

		face = Int64.(floor.(source))




	# Add original edges.
	# For each node, add an edge to (+0, +1), and to (+1, +0).
	for x = 1:X+1
		for y = 1:Y+1
			node = nodes[(x, y)]
			# Add the up and right edges only.
			for (_nPos, faceOffset) in [((0, 1), (-1, 0)), ((1, 0), (0, -1))]
				nPos = (x, y) .+ _nPos
				if haskey(nodes, nPos)
					neighbor = nodes[nPos]
					faces = ((x, y), (x, y) .+ faceOffset)
					cost = min(costAt(costs, faces[1]), costAt(costs, faces[2]))
					edgeOut = Edge(neighbor, cost, true)
					edgeIn = Edge(node, cost, true)
					#newEdge = Edge(faces, true, cost)
					push!(node.neighbors, edgeOut)
					push!(neighbor.neighbors, edgeIn)
				end
			end
		end
	end
	return nodes, nodesByFace
end

@test constructOriginalGraph(zeros(Float64, (0, 0)))[1] == Dict{Position, Node}((1, 1)=>Node((1, 1)))

minimalCosts::Matrix{Float64} = zeros(Float64, (1, 1)).+5
minimalNodes = Dict{Position, Node}(
	(1, 1) => Node((1, 1), [], [(1, 1)]),
	(1, 2) => Node((1, 2), [], [(1, 1)]),
	(2, 1) => Node((2, 1), [], [(1, 1)]),
	(2, 2) => Node((2, 2), [], [(1, 1)]))


push!(minimalNodes[(1,1)].neighbors, Edge(minimalNodes[1, 2], 5.0))
push!(minimalNodes[(1,1)].neighbors, Edge(minimalNodes[2, 1], 5.0))
push!(minimalNodes[(1,2)].neighbors, Edge(minimalNodes[1, 1], 5.0))
push!(minimalNodes[(1,2)].neighbors, Edge(minimalNodes[2, 2], 5.0))
push!(minimalNodes[(2,1)].neighbors, Edge(minimalNodes[1, 1], 5.0))
push!(minimalNodes[(2,1)].neighbors, Edge(minimalNodes[2, 2], 5.0))
push!(minimalNodes[(2,2)].neighbors, Edge(minimalNodes[1, 2], 5.0))
push!(minimalNodes[(2,2)].neighbors, Edge(minimalNodes[2, 1], 5.0))

(g, nbe) = constructOriginalGraph(minimalCosts)
@test g == minimalNodes


function divideOriginalEdges!(nodes :: Dict{Position, Node})
	# for node in nodes
	# 	for edge in node.neighbors
	# 		distance = norm(edge.node.pos - edge.node)
	# 	end
	# end

end

function connectAcrossFaces!(nodes :: Dict{Position, Node}, nodesByFace, costs)
	for (face, nodes) in nodesByFace
		for source in nodes
			for target in nodes
				# These are _across_ face if they don't share the exact same faces.
				# Otherwise they are on an edge and we don't add anything.
				if Set(source.faces) != Set(target.faces)
					push!(source.neighbors, Edge(target, costAt(costs, face), false))
				end
			end
		end
	end
end


function shortestPath(source::Position, target::Position, costs, numSteps) LinkedList{Edge}
	# Step 1 - construct G0 with nodes and edges
	nodes, nodesByFace = constructOriginalGraph(costs)

	# Add source and target positions.
	# Mmaybe this is not necessary and we can restrict to being on the grid.
	for pos in [source, target]
		if !haskey(nodes, pos)
			face = Int64.(floor.(pos))
			nodes[pos] = Node(pos, [], [face])
			push!(nodesByFace[face], nodes[pos])
		end
	end


	path :: LinkedList{Edge} = nil(Edge)
	pathCost :: Float64 = Inf

	for i in 1:numSteps
		# Add all the nodes from the path
		for edge in path
			nodes[edge.node.pos] = edge.node
		end

		# Step 2 - construct G_{n+1}
		# Add steiner points
		divideOriginalEdges!(nodes)
		connectAcrossFaces!(nodes, nodesByFace, costs)

		# Step 3 - a-star G_n
		path = reverse(astar(nodes[source], nodes[target]))
	end
	return path
end

println(shortestPath((1.0, 1.0), (3.0, 3.0), zeros(Float64, (10, 10)).+1, 1))
