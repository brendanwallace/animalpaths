using DataStructures
using LinearAlgebra
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
	sort(x.neighbors) == sort(y.neighbors) && sort(x.faces) == sort(y.faces)


struct Edge <: _Edge
	node :: Node
	cost :: Float64
	isOriginal :: Bool
	# faces :: Tuple{Face, Face}
	Edge(node, cost) = new(node, cost, true)
	Edge(node, cost, isOriginal) = new(node, cost, isOriginal)
end

function Base.isless(x::Edge, y::Edge)
	if x.node.position[1] < y.node.position[1]
		return true
	else
		return x.node.position[2] < y.node.position[2]
	end
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
	
	# For each face, add the nodes on it
	for x = 0:X+1
		for y = 0:Y+1
			face :: Face = (x, y)
			nodesByFace[face] = []
			for (dx, dy) in [(0, 0), (0, 1), (1, 0), (1, 1)]
				(_x, _y) = (x, y) .+ (dx, dy)
				if haskey(nodes, (_x, _y))
					node = nodes[(_x, _y)]
					push!(node.faces, face)
					# Don't save the faces that are not real
					if _x >= 1 && x <= X && _y >= 1 && y <= Y
						push!(nodesByFace[face], node)
					end
				end
			end
		end
	end


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

@test constructOriginalGraph(zeros(Float64, (0, 0)))[1] == Dict{Position, Node}((1, 1)=>Node((1, 1), [], [(0, 0), (0, 1), (1, 0), (1, 1)]))

minimalCosts::Matrix{Float64} = zeros(Float64, (1, 1)).+5
minimalNodes = Dict{Position, Node}(
	(1, 1) => Node((1, 1), [], [(1, 1), (0, 0), (1, 0), (0, 1)]),
	(1, 2) => Node((1, 2), [], [(1, 2), (0, 1), (1, 1), (0, 2)]),
	(2, 1) => Node((2, 1), [], [(2, 1), (1, 0), (2, 0), (1, 1)]),
	(2, 2) => Node((2, 2), [], [(2, 2), (1, 1), (2, 1), (1, 2)]))


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


function findNumSteinerPoints(distance)
	return 2
end


# Divides original edges
function divideOriginalEdges!(nodes :: Dict{Position, Node}, nodesByFace=nothing, findNumSteinerPoints=(x)->2)
	for (_pos, source) in copy(nodes)
		# println("considering: ", source)
		# sleep(1.0)
		for originalEdge in copy(source.neighbors)
			# println("looping through neighbors: ", source.neighbors)
			# sleep(1.0)
			# delete the originalEdge and add numSteinerPoints new originalEdges
			# TODO - figure out if it's an issue that we're not handling
			# paired originalEdges.
			if originalEdge.isOriginal
				# This is incredibly verbose. Seems like there should be a more succint array delete.
				deleteat!(source.neighbors, findfirst(isequal(originalEdge), source.neighbors))

				# Vector that points in the direction of the edge
				originalEdgeVector = originalEdge.node.position .- source.position
				# println(originalEdgeVector)
				numSteinerPoints = findNumSteinerPoints(norm(originalEdgeVector))
				originalEdgeFaces = intersect(source.faces, originalEdge.node.faces)
				@assert length(originalEdgeFaces) == 2 # nodes on an edge should have exactly 2 faces

				# Add all the steiner points.
				newEdgeCost = originalEdge.cost * (1 / (numSteinerPoints)) 
				from = source
				for d in 1:(numSteinerPoints - 1)
					newEdgeVector = (d / (numSteinerPoints)) .* originalEdgeVector
					# println("newEdgeVector: ", newEdgeVector)
					newPosition = source.position .+ newEdgeVector
					# println("newPosition: ", newPosition)
					# TODO – this could lead to a weird duplication bug possibly.
					# If we add edges from a node that we haven't iterated over yet,
					# then we may end up subdividing those edges prematurely.
					#
					# Counterpoint: I think we only look at each node once, so we
					# only look at each node's neighbors once.
					if haskey(nodes, newPosition)
						steinerPointNode = nodes[newPosition]
					else
						steinerPointNode = Node(newPosition, [], originalEdgeFaces)
						nodes[newPosition] = steinerPointNode
						if nodesByFace != nothing
							for face in originalEdgeFaces
								push!(nodesByFace[face], steinerPointNode)
							end
						end
					end
					newEdge = Edge(steinerPointNode, newEdgeCost, true)
					push!(from.neighbors, newEdge)
					from = steinerPointNode
				end
				# Add the final edge -- which we know is to originalEdge.node
				newEdge = Edge(originalEdge.node, newEdgeCost, true)
				push!(from.neighbors, newEdge)
			end
		end
	end
end

doeNode1 = Node((1, 1), [], [(1, 1), (0, 0), (0, 1), (1, 0)])
doeNode2 = Node((2, 1), [], [(2, 1), (1, 0), (1, 1), (2, 0)])
doeEdge1 = Edge(doeNode2, 8.0, true)
doeEdge2 = Edge(doeNode1, 8.0, true)
push!(doeNode1.neighbors, doeEdge1)
push!(doeNode2.neighbors, doeEdge2)

doeNodes = Dict((1.0, 1.0) => doeNode1, (2.0, 1.0) => doeNode2)
divideOriginalEdges!(doeNodes)
@test doeNodes[(1.5, 1.0)].position == (1.5, 1.0)
@test doeNodes[(1.0, 1.0)].neighbors == [Edge(doeNodes[(1.5, 1)], 4.0, true)]
@test doeNodes[(1.5, 1.0)].neighbors == [Edge(doeNodes[(2, 1)], 4.0, true), Edge(doeNodes[(1, 1)], 4.0, true)]
@test doeNodes[(2.0, 1.0)].neighbors == [Edge(doeNodes[(1.5, 1)], 4.0, true)]

doeCopy = deepcopy(doeNodes)
divideOriginalEdges!(doeNodes)
divideOriginalEdges!(doeNodes)
divideOriginalEdges!(doeCopy, nothing, (x)->4)
@test doeCopy == doeNodes


function connectAcrossFaces!(nodes :: Dict{Position, Node}, nodesByFace, costs)
	for (face, nodes) in nodesByFace
		for source in nodes
			for target in nodes
				# These are _across_ face if they don't share the exact same faces.
				# Otherwise they are on an edge and we don't add anything.
				if length(intersect(source.faces, target.faces)) < 2
					len = norm(target.position .- source.position)
					push!(source.neighbors, Edge(target, len * costAt(costs, face), false))
				end
			end
		end
	end
end

g[1.5, 1.5] = Node((1.5, 1.5), [], [(1, 1)])
push!(nbe[(1, 1)], g[(1.5, 1.5)])
connectAcrossFaces!(g, nbe, minimalCosts)


function toArray(path :: LinkedList{Edge}) Array{Edge}
	arrayPath = Array{Edge}(undef, length(path))
	for i = 1:length(path)
		arrayPath[i] = path.head
		path = path.tail
	end
	return arrayPath
end

function shortestPath(source::Position, target::Position, costs, deltaThreshold=0.1, numPoints=(x)->2) Array{Edge}
	@info "searching from $(source) to $(target)"

	# Step 1 - construct G0 with nodes and edges
	nodes, nodesByFace = constructOriginalGraph(costs)

	# Add source and target positions.
	# Maybe this is not necessary and we can restrict to being on the grid.
	for pos in [source, target]
		if !haskey(nodes, pos)
			face = Int64.(floor.(pos))
			nodes[pos] = Node(pos, [], [face])
			push!(nodesByFace[face], nodes[pos])
		end
	end

	path :: Array{Edge} = []
	pathCost :: Float64 = Inf
	delta = Inf
	i = 1

	while delta > deltaThreshold
		# Add all the nodes from the path
		# TODO – remove nodes we don't need anymore
		if i > 1
			sourceNode = nodes[source]
			nodes = Dict(source => sourceNode)
			nodesByFace = Dict{Face, Array{Node}}()
			for edge in path
				nodes[edge.node.position] = edge.node
			end
			for (_key, node) in nodes
				for face in node.faces
					if !haskey(nodesByFace, face)
						nodesByFace[face] = []
					end
					push!(nodesByFace[face], node)
				end
			end
		end


		# Step 2 - construct G_{n+1}
		# Add steiner points
		divideOriginalEdges!(nodes, nodesByFace, numPoints)
		connectAcrossFaces!(nodes, nodesByFace, costs)

		@info "step $(i) – searching over $(length(nodes)) nodes"

		# Step 3 - a-star G_n
		path = toArray(reverse(astar(nodes[source], nodes[target])))
		newPathCost = sum(map(x->x.cost, path))
		delta = pathCost - newPathCost
		pathCost = newPathCost
		i += 1

		@info "found path of cost $(pathCost)"
	end
	return path
end

@test length(shortestPath((1.0, 1.0), (3.0, 3.0), zeros(Float64, (10, 10)).+1, 1)) == 2
@test length(shortestPath((3.0, 3.0), (1.0, 1.0), zeros(Float64, (10, 10)).+1, 1)) == 2
@test length(shortestPath((10.0, 10.0), (1.0, 1.0), zeros(Float64, (10, 10)).+1, 1)) == 9
@test length(shortestPath((1.0, 1.0), (1.5, 1.5), zeros(Float64, (2, 2)).+1, 1)) == 1
@test length(shortestPath((1.0, 1.0), (1.5, 1.5), zeros(Float64, (2, 2)).+1, 2)) == 1

cost(s) = sum(map(x->x.cost, s))

δ = 0.01
tolerance = 0.1
@test cost(shortestPath((1.0, 1.0), (10.0, 10.0), zeros(Float64, (10, 10)).+1, δ, (x)->2)) ≈ norm((9, 9))
@test cost(shortestPath((1.0, 1.0), (10.0, 10.0), zeros(Float64, (10, 10)).+5, δ, (x)->2)) ≈ 5*norm((9, 9))
@test cost(shortestPath((1.0, 1.0), (4.0, 5.0), zeros(Float64, (10, 10)).+5, δ, (x)->2)) - 5*5 < tolerance
