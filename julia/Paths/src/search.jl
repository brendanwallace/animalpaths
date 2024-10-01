using DataStructures: LinkedList, cons, nil, PriorityQueue, enqueue!, dequeue!, DefaultDict
using Test, TestItems
using LinearAlgebra: norm

# include("common.jl")


# This is the bottom-left corner of the square face.
const Face = GridPosition

abstract type _Edge end

# @assert false


struct Node
	position :: Position
	neighbors :: Vector{_Edge}
	# faces :: Vector{Face}
end

Node(pos) = Node(pos, [])

function faces(pos::Position) :: Array{Face}
	δ = 0.001
	x, y = pos
	if mod(x, 1) == 0 && mod(y, 1) == 0
		return [Int64.(p) for p in [(x, y), (x-1, y), (x, y-1), (x-1, y-1)]]
	elseif mod(x, 1) == 0
		return [Int64.(floor.(p)) for p in [(x, y), (x-1, y)]]
	elseif mod(y, 1) == 0
		return [Int64.(floor.(p)) for p in [(x, y), (x, y-1)]]
	else
		return [Int64.(floor.(pos))]
	end
end


function faces(node::Node) :: Array{Face}
	return faces(node.position)
end


# Otherwise == just sees that the array pointers are different and calls the
# structs different.
# Uncommenting the neighbor comparison lets us do deep equality testing by default.
Base.:(==)(x::Node, y::Node) = x.position == y.position #&& sort(x.neighbors) == sort(y.neighbors)


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

Base.show(io::IO, e::Edge) = print(io, "->$(e.node.position), $(e.isOriginal), $(e.cost)")

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


function cornerPositions(face::Face)
	return map(x -> x .+ (face[1], face[2]), [(0, 0), (0, 1), (1, 0), (1, 1)])
end

@test cornerPositions((5, 5)) == [(5, 5), (5, 6), (6, 5), (6, 6)]


function addCorners!(face, nodesByPosition)::Array{Node}
	corners = Node[]
	for cornerPos in cornerPositions(face)
		if haskey(nodesByPosition, cornerPos)
			node = nodesByPosition[cornerPos]
		else
			node = Node(cornerPos)
			nodesByPosition[cornerPos] = node
		end
		push!(corners, node)
	end
	return corners
end


function subdivideEdge!(source::Node, target::Node, edgeCost, nodesByPosition::Dict{Position, Node}, numSteinerPoints::Int64)
	# Vector that points in the direction of the edge
	steinerPointNodes = Node[]
	originalEdgeVector = target.position .- source.position
	newEdgeCost = edgeCost * (1.0 / Float64(numSteinerPoints)) 
	from = source
	for d in 1:(numSteinerPoints - 1)
		newEdgeVector = (d / (numSteinerPoints)) .* originalEdgeVector
		newPosition = source.position .+ newEdgeVector
		# TODO – this could lead to a weird duplication bug possibly.
		# If we add edges from a node that we haven't iterated over yet,
		# then we may end up subdividing those edges prematurely.
		#
		# Conversely, I think we only look at each node once, so we
		# only look at each node's neighbors once.
		if haskey(nodesByPosition, newPosition)
			steinerPointNode = nodesByPosition[newPosition]	
		else
			steinerPointNode = Node(newPosition, [])
			nodesByPosition[newPosition] = steinerPointNode
		end
		newEdge = Edge(steinerPointNode, newEdgeCost, true)
		push!(from.neighbors, newEdge)
		from = steinerPointNode
		push!(steinerPointNodes, steinerPointNode)
	end
	# Add the final edge -- which we know is to originalEdge.node
	newEdge = Edge(target, newEdgeCost, true)
	push!(from.neighbors, newEdge)
	return steinerPointNodes
end


function connectAcrossEdges!(corners, faceCost, nodesByPosition, numSteinerPoints)
	steinerPoints = Vector{Node}()
	for source in corners
		for target in corners
			# These are the conditions for connecting a corner. ⊻ is XOR.
			if (source.position[1] == target.position[1]) ⊻ (source.position[2] == target.position[2])
				# I think it's ok to duplicate this edge.
				# TODO -- neighbors could be a dictionary so we can easily look
				# up and update edges.
				## connect towards, adding steiner points as necessary.
				newNodes = subdivideEdge!(source, target, faceCost, nodesByPosition, numSteinerPoints)
				steinerPoints = vcat(steinerPoints, newNodes)
			end
		end
	end
	return steinerPoints
end




function connectAcrossFace!(nodes, faceCost::Float64)
	for source in nodes
		for target in nodes
			if ((source.position[1] != target.position[1]) && (source.position[2] != target.position[2]))
				len = norm(target.position .- source.position)
				push!(source.neighbors, Edge(target, len * faceCost, false))
			end
		end
	end
end


# After calling this function, all 
function exploreFace!(nodesByPosition, face, costs, numSteinerPoints)
	# Nodes on the new face.
	faceCost = costAt(costs, face)
	corners = addCorners!(face, nodesByPosition)
	steinerPoints = connectAcrossEdges!(corners, faceCost, nodesByPosition, numSteinerPoints)
	connectAcrossFace!(vcat(corners, steinerPoints), faceCost)
	@debug "added $(length(corners)) corners and $(length(steinerPoints)) steiner Points"
end


# Explores all the faces this node is adjacent to, thereby providing all
# possible neighbors.
function populateNeighbors!(node, nodesByPosition, visitedFaces, costs, numSteinerPoints)
	@debug "populating neighbors of $(node)"
	for face in faces(node.position)
		x, y = face
		X, Y = size(costs)
		@debug "$(face) in $(visitedFaces): $(face in visitedFaces)"
		if x >= 1 && y >= 1 && x <= X && y <= Y && !(face in visitedFaces)
			push!(visitedFaces, face)
			exploreFace!(nodesByPosition, face, costs, numSteinerPoints)
			@debug "exploring face $(face). faces explored: $(visitedFaces)"
		end
	end
end

# nodesByPosition = Dict{Position, Node}((1., 1.) => Node((1., 1.)))
# visitedFaces = Set{Face}()
# tcosts = [2. 3. 1.; 1. 3. 1.; 1. 1. 1.]
# @test populateNeighbors!(nodesByPosition[(1., 1.)], nodesByPosition, visitedFaces, tcosts); true


# Divides original edges
# TODO -- don't use explicit saved faces, and generate this graph on the fly.
function divideOriginalEdges!(nodesByPosition :: Dict{Position, Node}, steinerPoints::Int64)
	for (_pos, source) in copy(nodesByPosition)
		for edge in copy(source.neighbors)
			# delete the originalEdge and add numSteinerPoints new originalEdges
			if edge.isOriginal
				delete!(source.neighbors, edge)
				subdivideEdge!(source, edge.node, edge.cost, nodesByPosition, steinerPoints)
			end
		end
	end
end


@testitem "Test divideOriginalEdges" begin
	using Test, Paths

	doeNode1 = Node((1, 1), [])
	doeNode2 = Node((2, 1), [])
	doeEdge1 = Edge(doeNode2, 8.0, true)
	doeEdge2 = Edge(doeNode1, 8.0, true)
	push!(doeNode1.neighbors, doeEdge1)
	push!(doeNode2.neighbors, doeEdge2)

	doeNodes = Dict((1.0, 1.0) => doeNode1, (2.0, 1.0) => doeNode2)
	Paths.divideOriginalEdges!(doeNodes, 2)
	@test doeNodes[(1.5, 1.0)].position == (1.5, 1.0)
	@test doeNodes[(1.0, 1.0)].neighbors == [Edge(doeNodes[(1.5, 1)], 4.0, true)]
	@test doeNodes[(1.5, 1.0)].neighbors == [Edge(doeNodes[(2, 1)], 4.0, true), Edge(doeNodes[(1, 1)], 4.0, true)]
	@test doeNodes[(2.0, 1.0)].neighbors == [Edge(doeNodes[(1.5, 1)], 4.0, true)]

	doeCopy = deepcopy(doeNodes)
	Paths.divideOriginalEdges!(doeNodes, 2)

	Paths.divideOriginalEdges!(doeNodes, 2)
	Paths.divideOriginalEdges!(doeCopy, 4)
	@test doeCopy == doeNodes
end


function connectAcrossFaces!(nodesByPosition :: Dict{Position, Node}, costs)
	nodesByFace = Dict{Face, Array{Node}}()
	for (_key, node) in nodesByPosition
	    for face in faces(node.position)
	        if !haskey(nodesByFace, face)
	            nodesByFace[face] = []
	        end
	        push!(nodesByFace[face], node)
	    end
	end
	for (face, nodes) in nodesByFace
		for source in nodes
			for target in nodes
				# These are _across_ face if they don't share the exact same faces.
				# Otherwise they are on an edge and we don't add anything.
				if ((source.position[1] != target.position[1]) && (source.position[2] != target.position[2]))
				# if length(intersect(source.faces, target.faces)) < 2
					len = norm(target.position .- source.position)
					push!(source.neighbors, Edge(target, len * costAt(costs, face), false))
				end
			end
		end
	end
end

# @testitem "Test connectAcrossFaces!" begin
# 	using Paths, Test


# 	minimalCosts::Matrix{Float64} = zeros(Float64, (1, 1)).+5
# 	minimalNodes = Dict{Paths.Position, Node}(
# 		(1, 1) => Node((1, 1), []),
# 		(1, 2) => Node((1, 2), []),
# 		(2, 1) => Node((2, 1), []),
# 		(2, 2) => Node((2, 2), []))


# 	push!(minimalNodes[(1,1)].neighbors, Edge(minimalNodes[1, 2], 5.0))
# 	push!(minimalNodes[(1,1)].neighbors, Edge(minimalNodes[2, 1], 5.0))
# 	push!(minimalNodes[(1,2)].neighbors, Edge(minimalNodes[1, 1], 5.0))
# 	push!(minimalNodes[(1,2)].neighbors, Edge(minimalNodes[2, 2], 5.0))
# 	push!(minimalNodes[(2,1)].neighbors, Edge(minimalNodes[1, 1], 5.0))
# 	push!(minimalNodes[(2,1)].neighbors, Edge(minimalNodes[2, 2], 5.0))
# 	push!(minimalNodes[(2,2)].neighbors, Edge(minimalNodes[1, 2], 5.0))
# 	push!(minimalNodes[(2,2)].neighbors, Edge(minimalNodes[2, 1], 5.0))

# 	(g, nbe) = Paths.constructOriginalGraph(minimalCosts)

# 	# Add an internal point
# 	g[1.5, 1.5] = Node((1.5, 1.5), [])
# 	push!(nbe[(1, 1)], g[(1.5, 1.5)])
# 	Paths.connectAcrossFaces!(g, minimalCosts)
# end


function resetNodes(sourceNode, path::Array{Node})
	nodesByPosition = Dict(sourceNode.position => sourceNode)
	for node in path
	    # Add the nodes we already saw
	    nodesByPosition[node.position] = node
	end
	for (_key, node) in copy(nodesByPosition)
	    # Add original edge neighbors
	    for edge in node.neighbors
	        if edge.isOriginal
	            nodesByPosition[(edge.node.position)] = edge.node
	        end
	    end
	end
	# Prune edges.
	# Go through every edge and delete the ones pointing to nodes that no
	# longer exist (i.e. are not in nodesByPosition).
	for (_key, node) in copy(nodesByPosition)
	    for edge in copy(node.neighbors)
	        if !haskey(nodesByPosition, edge.node.position)
	            Paths.delete!(node.neighbors, edge)
	        end
	    end
	end
	return nodesByPosition
end


function heuristic(pos :: Position, target :: Position) :: Float64
	return 1.0 * norm(pos .- target)
end

function astar(start::T, goal::T, neighbors::Function, h::Function) where {T}

	bestCost = DefaultDict{T, Float64}(Inf)
	pq = PriorityQueue{T, Float64}()
	cameFrom = Dict{T, T}()

	bestCost[start] = 0.0
	pq[start] = h(start)

	# pop the top element and add its neighbors
	while !isempty(pq)
		# Pop the cheapest element.
		current = dequeue!(pq)
		# If we arrived at the target, use cameFrom to unroll the path.
		if current == goal
			path::Array{T} = [current]
			cost::Float64 = bestCost[goal]
			while current != start
				current = cameFrom[current]
				push!(path, current)
			end
			return (reverse(path), cost)
		end

		# Only add neighbors to the queue if this path to them is cheaper than
		# what we've already got in the queue.
		for (neighbor, cost) in neighbors(current)
			tentativeCost = bestCost[current] + cost
			if tentativeCost < bestCost[neighbor]
				bestCost[neighbor] = tentativeCost
				pq[neighbor] = tentativeCost + h(neighbor)
				cameFrom[neighbor] = current
			end
		end

	end
	# This means we couldn't find a path.
	return (Array{T}[], Inf)
end




@testitem "Test for astar" begin
using Paths, Test

	# We can move right or left on the number-line.
	function intNeighbors(x)
		return [((x + 1), 1), ((x - 1), 1)]
	end
	@test Paths.astar(1, 3, intNeighbors, (x) -> 3 - x) == ([1, 2, 3], 2.0)




	neighborF = (n) -> [(e.node, e.cost) for e in n.neighbors]
	hF = (n) -> 0.0

	n1 = Node((1, 1))
	e1 = Edge(n1, 10.0)
	e2 = Edge(n1, 15.0)
	n2 = Node((2, 2))
	push!(n2.neighbors, e1)
	push!(n2.neighbors, e2)


	@test Paths.astar(Node((1, 1)), Node((2, 2)), neighborF, hF) == (Array{Node}[], Inf)
	@test Paths.astar(n2, n1, neighborF, hF) == ([n2, n1], 10.0)

	e3 = Edge(n2, 1.0)
	e4 = Edge(n1, 20.0)
	n3 = Node((3.0, 3.0), [e3, e4])

	# @test Paths.astar(n3, n1, neighborF, hF) == list(e1, e3)
end


function shortestPath(source::Position, target::Position, costs::Matrix{Float64}, deltaThreshold=0.01, steinerPoints::Int64=2)::Tuple{Array{Node}, Float64}
	# TODO – switch these to rounding instead of flooring.
	# TODO – check to make sure these are inbounds?
	source = floor.(source)
	target = floor.(target)

	@debug "searching from $(source) to $(target)"

	nodesByPosition = Dict{Paths.Position, Node}(source => Node(source), target => Node(target))
	visitedFaces = Set{Paths.Face}()
	initialNeighbors = (node) -> (
		Paths.populateNeighbors!(node, nodesByPosition, visitedFaces, costs, steinerPoints);
    	return [(e.node, e.cost) for e in node.neighbors])
	heuristic = n->norm(n.position .- target)

	# Step 1 - construct G0 with nodesByPosition and edges
	# @debug "constructing original graph"
	# nodesByPosition, nodesByFace = constructOriginalGraph(costs)


	@debug "running initial search"
	# path = []
	# pathCost = Inf
	path, pathCost = astar(nodesByPosition[source], nodesByPosition[target], initialNeighbors, heuristic)
	@debug "initial astar search populated $(length(nodesByPosition)) nodesByPosition"

	delta = Inf
	i = 1

	while delta > deltaThreshold
		# Remove unneeded nodesByPosition only after the first initial search.
		# TODO - actually remove unneeded nodesByPosition now.
		# if i > 1
			nodesByPosition = resetNodes(nodesByPosition[source], path)
		# end


		# Step 2 - construct G_{n+1}
		# Add steiner points
		@debug "adding steiner points"
		divideOriginalEdges!(nodesByPosition, steinerPoints)

		@debug "connecting edges"
		connectAcrossFaces!(nodesByPosition, costs)

		@debug "step $(i) – searching over $(length(nodesByPosition)) nodesByPosition"
		# Step 3 - a-star G_n
		neighbors = (n)->[(e.node, e.cost) for e in n.neighbors]
		# h = n->norm(n.position .- nodesByPosition[target].position)
		path, newPathCost = astar(nodesByPosition[source], nodesByPosition[target], neighbors, heuristic)
		delta = pathCost - newPathCost
		pathCost = newPathCost
		i += 1

		@debug "found path of cost $(pathCost)"
	end
	return (path, pathCost)
end


@testitem "Test shortestPath" begin
	using Test, Paths, LinearAlgebra

	p, c = Paths.shortestPath((1.0, 1.0), (3.0, 3.0), zeros(Float64, (10, 10)).+1); @test length(p) == 3
	p, c = Paths.shortestPath((3.0, 3.0), (1.0, 1.0), zeros(Float64, (10, 10)).+1, 1); @test length(p) == 3
	p, c = Paths.shortestPath((10.0, 10.0), (1.0, 1.0), zeros(Float64, (10, 10)).+1, 1); @test length(p) == 10

	# These are broken because search goes from vertex to vertex only.
	# @test length(shortestPath((1.0, 1.0), (1.5, 1.5), zeros(Float64, (2, 2)).+1, 1)) == 1
	# @test length(shortestPath((1.0, 1.0), (1.5, 1.5), zeros(Float64, (2, 2)).+1, 2)) == 1
	# @test length(shortestPath((1.5, 1.0), (1.5, 1.5), zeros(Float64, (2, 2)).+1, 2)) == 1


	δ = 0.01
	tolerance = 0.1
	p, c = Paths.shortestPath((1.0, 1.0), (10.0, 10.0), zeros(Float64, (10, 10)).+1, δ, 2); @test c ≈ norm((9, 9))
	p, c = Paths.shortestPath((1.0, 1.0), (10.0, 10.0), zeros(Float64, (10, 10)).+5, δ, 2); @test c ≈ 5*norm((9, 9))
	p, c = Paths.shortestPath((1.0, 1.0), (4.0, 5.0), zeros(Float64, (10, 10)).+5, δ, 2); @test c - 5*5 < tolerance
	p, c = Paths.shortestPath((2.0, 2.0), (5.0, 5.0),
		[1.0 1.0 1.0 1.0 1.0;
	     1.0 5.0 5.0 5.0 5.0;
	     1.0 5.0 5.0 5.0 5.0;
	     1.0 5.0 5.0 5.0 5.0;
	     1.0 1.0 1.0 1.0 1.0;]); @test c ≈ 6.0

end
