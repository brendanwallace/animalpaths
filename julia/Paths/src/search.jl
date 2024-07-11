# This is the bottom-left corner of the square face.
const Face = GridPosition

abstract type _Edge end

# @assert false


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


function heuristic(pos :: Position, target :: Position) :: Float64
	return 1.0 * norm(pos .- target)
end

function astar(source::Node, target::Node)::LinkedList{Edge}

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
				enqueue!(pq, Item(edge.node, cons(edge, item.path), cost), (cost + heuristic(edge.node.position, target.position)))
			end
		end
	end

	# This means we couldn't find a path.
	return nil(Edge)
end



@testitem "Test for astar" begin
using Paths, Test, DataStructures

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

function constructOriginalGraph(costs::Matrix{Float64})
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

@testitem "constructOriginalGraph" begin
using Paths, Test

@test Paths.constructOriginalGraph(
	zeros(Float64, (0, 0)))[1] == Dict{Paths.Position, Node}(
	(1, 1)=>Node((1, 1), [], [(0, 0), (0, 1), (1, 0), (1, 1)]))

minimalCosts::Matrix{Float64} = zeros(Float64, (1, 1)).+5
minimalNodes = Dict{Paths.Position, Node}(
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

(g, nbe) = Paths.constructOriginalGraph(minimalCosts)
@test g == minimalNodes

lg, lnbe = Paths.constructOriginalGraph(zeros(Float64, (100, 100)))
for (key, node) in lg
	@test length(node.faces) == 4
end
end

function faces(pos)
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



# Divides original edges
# TODO -- don't use explicit saved faces, and generate this graph on the fly.
function divideOriginalEdges!(nodes :: Dict{Position, Node}, nodesByFace=nothing, findNumSteinerPoints=(x)->2)
	for (_pos, source) in copy(nodes)
		for originalEdge in copy(source.neighbors)
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
				originalEdgeFaces = faces((source.position .+ originalEdge.node.position) ./ 2)
				# Add all the steiner points.
				newEdgeCost = originalEdge.cost * (1 / (numSteinerPoints)) 
				from = source
				for d in 1:(numSteinerPoints - 1)
					newEdgeVector = (d / (numSteinerPoints)) .* originalEdgeVector
					# println("newEdgeVector: ", newEdgeVector)
					newPosition = source.position .+ newEdgeVector
					# TODO – this could lead to a weird duplication bug possibly.
					# If we add edges from a node that we haven't iterated over yet,
					# then we may end up subdividing those edges prematurely.
					#
					# Conversely, I think we only look at each node once, so we
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


@testitem "Test divideOriginalEdges" begin
	using Test, Paths

	doeNode1 = Node((1, 1), [], [(1, 1), (0, 0), (0, 1), (1, 0)])
	doeNode2 = Node((2, 1), [], [(2, 1), (1, 0), (1, 1), (2, 0)])
	doeEdge1 = Edge(doeNode2, 8.0, true)
	doeEdge2 = Edge(doeNode1, 8.0, true)
	push!(doeNode1.neighbors, doeEdge1)
	push!(doeNode2.neighbors, doeEdge2)

	doeNodes = Dict((1.0, 1.0) => doeNode1, (2.0, 1.0) => doeNode2)
	Paths.divideOriginalEdges!(doeNodes)
	@test doeNodes[(1.5, 1.0)].position == (1.5, 1.0)
	@test doeNodes[(1.0, 1.0)].neighbors == [Edge(doeNodes[(1.5, 1)], 4.0, true)]
	@test doeNodes[(1.5, 1.0)].neighbors == [Edge(doeNodes[(2, 1)], 4.0, true), Edge(doeNodes[(1, 1)], 4.0, true)]
	@test doeNodes[(2.0, 1.0)].neighbors == [Edge(doeNodes[(1.5, 1)], 4.0, true)]

	# for (key, node) in doeNodes
	# 	@test length(node.faces) >= 2
	# end

	doeCopy = deepcopy(doeNodes)
	Paths.divideOriginalEdges!(doeNodes)

	# for (key, node) in doeNodes
	# 	@test length(node.faces) >= 2
	# end

	Paths.divideOriginalEdges!(doeNodes)

	# for (key, node) in doeNodes
	# 	@test length(node.faces) >= 2
	# end

	Paths.divideOriginalEdges!(doeCopy, nothing, (x)->4)
	@test doeCopy == doeNodes

	# for (key, node) in doeCopy
	# 	@test length(node.faces) >= 2
	# end
end


function connectAcrossFaces!(nodes :: Dict{Position, Node}, nodesByFace, costs)
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

@testitem "Test connectAcrossFaces!" begin
	using Paths, Test


	minimalCosts::Matrix{Float64} = zeros(Float64, (1, 1)).+5
	minimalNodes = Dict{Paths.Position, Node}(
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

	(g, nbe) = Paths.constructOriginalGraph(minimalCosts)

	# Add an internal point
	g[1.5, 1.5] = Node((1.5, 1.5), [], [(1, 1)])
	push!(nbe[(1, 1)], g[(1.5, 1.5)])
	Paths.connectAcrossFaces!(g, nbe, minimalCosts)
end


function toArray(path :: LinkedList{Edge}) Array{Edge}
	arrayPath = Array{Edge}(undef, length(path))
	for i = 1:length(path)
		arrayPath[i] = path.head
		path = path.tail
	end
	return arrayPath
end

function resetNodes(sourceNode, path)
	nodeDict = Dict(sourceNode.position => sourceNode)
	nodesByFace = Dict{Paths.Face, Array{Node}}()
	for step in path
	    # Add the nodes we already saw
	    nodeDict[step.node.position] = step.node
	end
	for (_key, node) in copy(nodeDict)
	    # Add original edge neighbors
	    for edge in node.neighbors
	        if edge.isOriginal
	            nodeDict[(edge.node.position)] = edge.node
	        end
	    end
	end
	# Prune edges
	for (_key, node) in copy(nodeDict)
	    for edge in copy(node.neighbors)
	        if !haskey(nodeDict, edge.node.position)
	            Paths.delete!(node.neighbors, edge)
	        end
	    end
	end

	for (_key, node) in nodeDict
	    for face in node.faces
	        if !haskey(nodesByFace, face)
	            nodesByFace[face] = []
	        end
	        push!(nodesByFace[face], node)
	    end
	end
	return nodeDict, nodesByFace
end


function shortestPath(source::Position, target::Position, costs::Matrix{Float64}, deltaThreshold=0.01, numPoints=(x)->2) Array{Edge}
	source = floor.(source)
	target = floor.(target)
	@debug "searching from $(source) to $(target)"

	# Step 1 - construct G0 with nodeDict and edges
	@debug "constructing original graph"
	nodeDict, nodesByFace = constructOriginalGraph(costs)

	# Add source and target positions.
	# Maybe this is not necessary and we can restrict to being on the grid.
	for pos in [source, target]
		if !haskey(nodeDict, pos)
			faces = unique([Int64.(floor.(pos .+ delta)) for delta in [(δ, 0), (0, δ), (-δ, 0), (0, -δ)]])
			nodeDict[pos] = Node(pos, [], faces)
			for face in faces
				push!(nodesByFace[face], nodeDict[pos])
			end
		end
	end

	path :: Array{Edge} = []
	pathCost :: Float64 = Inf
	delta = Inf
	i = 1

	while delta > deltaThreshold
		# Remove unneeded nodeDict only after the first initial search.
		# TODO - actually remove unneeded nodeDict now.
		if i > 1
			nodeDict, nodesByFace = resetNodes(nodeDict[source], path)
		end


		# Step 2 - construct G_{n+1}
		# Add steiner points
		@debug "adding steiner points"
		divideOriginalEdges!(nodeDict, nodesByFace, numPoints)

		@debug "connecting edges"
		connectAcrossFaces!(nodeDict, nodesByFace, costs)

		@debug "step $(i) – searching over $(length(nodeDict)) nodeDict"
		# Step 3 - a-star G_n
		path = toArray(reverse(astar(nodeDict[source], nodeDict[target])))
		newPathCost = sum(map(x->x.cost, path))
		delta = pathCost - newPathCost
		pathCost = newPathCost
		i += 1

		@debug "found path of cost $(pathCost)"
	end
	return path
end


@testitem "Test shortestPath" begin
	using Test, Paths, LinearAlgebra

	@test length(Paths.shortestPath((1.0, 1.0), (3.0, 3.0), zeros(Float64, (10, 10)).+1, 1)) == 2
	@test length(Paths.shortestPath((3.0, 3.0), (1.0, 1.0), zeros(Float64, (10, 10)).+1, 1)) == 2
	@test length(Paths.shortestPath((10.0, 10.0), (1.0, 1.0), zeros(Float64, (10, 10)).+1, 1)) == 9
	# @test length(shortestPath((1.0, 1.0), (1.5, 1.5), zeros(Float64, (2, 2)).+1, 1)) == 1
	# @test length(shortestPath((1.0, 1.0), (1.5, 1.5), zeros(Float64, (2, 2)).+1, 2)) == 1
	# @test length(shortestPath((1.5, 1.0), (1.5, 1.5), zeros(Float64, (2, 2)).+1, 2)) == 1

	cost(s) = sum(map(x->x.cost, s))

	δ = 0.01
	tolerance = 0.1
	@test cost(Paths.shortestPath((1.0, 1.0), (10.0, 10.0), zeros(Float64, (10, 10)).+1, δ, (x)->2)) ≈ norm((9, 9))
	@test cost(Paths.shortestPath((1.0, 1.0), (10.0, 10.0), zeros(Float64, (10, 10)).+5, δ, (x)->2)) ≈ 5*norm((9, 9))
	@test cost(Paths.shortestPath((1.0, 1.0), (4.0, 5.0), zeros(Float64, (10, 10)).+5, δ, (x)->2)) - 5*5 < tolerance
	@test cost(Paths.shortestPath((2.0, 2.0), (5.0, 5.0),
		[1.0 1.0 1.0 1.0 1.0;
	     1.0 5.0 5.0 5.0 5.0;
	     1.0 5.0 5.0 5.0 5.0;
	     1.0 5.0 5.0 5.0 5.0;
	     1.0 1.0 1.0 1.0 1.0;])) ≈ 6.0

end


