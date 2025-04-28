const DICT_SIGS = 4

"""
Rounds to 4 significant digits, for use in nodesByPosition dictionary
to make sure we're not missing node lookup due to float errors.
"""
function r(pos)
    return round.(pos, sigdigits=DICT_SIGS)
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

"""
Positions of the corners of a face, where a face is referenced by the position
of its lower-left corner.
"""
function cornerPositions(face::Face)
    return map(x -> x .+ (face[1], face[2]), [(0, 0), (0, 1), (1, 0), (1, 1)])
end

@test cornerPositions((5, 5)) == [(5, 5), (5, 6), (6, 5), (6, 6)]

"""
Returns the corners on a face.
"""
function addCorners!(face, nodesByPosition, bc::BoundaryConditions, X, Y)::Array{Node}
    corners = Node[]
    for cornerPos in cornerPositions(face)
        if bc == PERIODIC
            cornerPos = (jmod(cornerPos[1], X), jmod(cornerPos[2], Y))
        end
        if haskey(nodesByPosition, r(cornerPos))
            node = nodesByPosition[r(cornerPos)]
        else
            node = Node(cornerPos)
            nodesByPosition[r(cornerPos)] = node
        end

        push!(corners, node)
    end
    return corners
end

"""
The logic of this feels kind of complicated. We're dealing with the situation
where we're subdividing an edge that's wrapping around the periodic boundary.

So you might see that you want to connect the point (1, 1) to the point (2, 1).
In that case, you just find the vector <p2 - p1> = <1, 0>, and take 1/2-length steps in
that direction.

But that breaks when you're wrapping around, because you'll see that (1, 1) is
neighbors with (5, 1). In *this* case, the step we want to take isn't <4, 0> – which
leads to super weird bugs – but actually in the direction <-1, 0>. And you can get to
that by computing `num - base`. Alternatively, going the other way from <5, 1> to, say,
<0.5, 1> we want `num + base` (num here would be -4.5).
"""
function correctForPeriodic(num::Number, base::Number)::Number
    # TODO - This is similar to the logic for periodic distance, and we should arguably
    # merge these two functions together.
    if base - abs(num) < abs(num)
        return num - sign(num) * base
    end
    return num
end


@testitem "Test correctforperiodic" begin
    using Test
    import Paths

    @test Paths.correctForPeriodic(-4.5, 5.0) == 0.5
    @test Paths.correctForPeriodic(4.5, 5.0) == -0.5
    @test Paths.correctForPeriodic(9.0, 10.0) == -1.0
    @test Paths.correctForPeriodic(-9.0, 10.0) == 1.0
    @test Paths.correctForPeriodic(1.0, 100.0) == 1.0
    @test Paths.correctForPeriodic(0.0, 100.0) == 0.0
end

# TODO - remove this after making sure correctForPeriodic.(vec, (X, Y)) works
# function correctForPeriodic(vec::Tuple{Number,Number}, bases::Tuple{Number,Number})
#     X, Y = bases
#     x, y = vec
#     return (correctForPeriodic(x, X), correctForPeriodic(y, Y))
# end

"""
Takes an *original* edge (i.e. part of the polyhedron) and adds (or looks up)
steiner points evenly across it, and creates (if they're absent) the edges.

It's necessary to still look all these things up even if we don't construct them
again because, as currently implemented, faces of the polyhedron don't know
what edges or nodes are on them.

This currently adds two versions of each edge, but one is potentially lower-cost.
# TODO - consider deduping edges and only adding the least-expensive one. It might
not really be worth the time to implement that though.
"""
function subdivideEdge!(source::Node, target::Node, edgeCost, nodesByPosition::Dict{Position,Node}, numSteinerPoints::Int64, bc, X, Y)
    @debug "subdividing from $(source.position) to $(target.position)"
    # Vector that points in the direction of the edge
    steinerPointNodes = Node[]
    originalEdgeVector = target.position .- source.position
    if norm(originalEdgeVector) > 1.0
        @debug "$(originalEdgeVector) from $(source.position) to $(target.position) is too long"

        originalEdgeVector = correctForPeriodic.(originalEdgeVector, (X, Y))

        @debug "using $(originalEdgeVector)"
        @assert norm(originalEdgeVector) <= 1.0
        # throw("ending there.")
    end
    newEdgeCost = edgeCost * (1.0 / Float64(numSteinerPoints + 1))
    from = source
    for d in 1:(numSteinerPoints)
        newEdgeVector = (d / (numSteinerPoints + 1)) .* originalEdgeVector
        newPosition = source.position .+ newEdgeVector
        if bc == PERIODIC
            newPosition = jmod(newPosition, (X, Y))
        end


        if haskey(nodesByPosition, r(newPosition))
            steinerPointNode = nodesByPosition[r(newPosition)]
        else
            steinerPointNode = Node(newPosition, [])
            nodesByPosition[r(newPosition)] = steinerPointNode
        end
        newEdge = Edge(steinerPointNode, newEdgeCost, true)
        @debug "new edge from $(from.position) $(newEdge)"
        push!(from.neighbors, newEdge) # pushOrUpdate!(from.neighbors, newEdge)
        from = steinerPointNode
        push!(steinerPointNodes, steinerPointNode)
    end
    # Add the final edge -- which we know is to originalEdge.node
    newEdge = Edge(target, newEdgeCost, true)
    @debug "new edge from $(from.position) $(newEdge)"
    push!(from.neighbors, newEdge)
    return steinerPointNodes
end


"""
Constructs (and subdivides) original edges between the corners of a square.
"""
function constructOriginalEdges(corners, faceCost, nodesByPosition, numSteinerPoints, bc, X, Y)
    steinerPoints = Vector{Node}()
    for source in corners
        for target in corners
            # These are the conditions for connecting a corner. ⊻ is XOR.
            if (source.position[1] == target.position[1]) ⊻ (source.position[2] == target.position[2])
                # I think it's ok to duplicate this edge.
                # TODO -- neighbors could be a dictionary so we can easily look
                # up and update edges.
                ## connect towards, adding steiner points as necessary.
                newNodes = subdivideEdge!(source, target, faceCost, nodesByPosition, numSteinerPoints, bc, X, Y)
                steinerPoints = vcat(steinerPoints, newNodes)
            end
        end
    end
    return steinerPoints
end



"""
Connects the nodes on a single face by creating edges between them.
"""
function connectAcrossFace!(nodes, faceCost::Float64, bc, X, Y)
    for source in nodes
        for target in nodes
            # Only connect the nodes that *don't* share an edge.
            # On a square grid, we can test for that by making sure that at one of their x and y
            # coordinates differ. (TODO - is relying on float equality bad here?)
            if ((source.position[1] != target.position[1]) && (source.position[2] != target.position[2]))
                len = norm(target.position .- source.position)
                if bc == PERIODIC
                    len = periodicNorm(target.position, source.position, X, Y)
                end
                push!(source.neighbors, Edge(target, len * faceCost, false))
            end
        end
    end
end


"""
After calling this function, all [... I'm not sure what I was writing here]
"""
function exploreFace!(nodesByPosition, face, costs, numSteinerPoints, bc::BoundaryConditions)
    # Nodes on the new face.
    X, Y = size(costs)
    faceCost = costAt(costs, face)
    # Look up or create all the corners.
    corners::Array{Node} = addCorners!(face, nodesByPosition, bc, X, Y)
    # Look up or create all the steiner points.
    steinerPoints = constructOriginalEdges(corners, faceCost, nodesByPosition, numSteinerPoints, bc, X, Y)
    connectAcrossFace!(vcat(corners, steinerPoints), faceCost, bc, X, Y)
    @debug "added $(length(corners)) corners and $(length(steinerPoints)) steiner Points"
end


"""
Explores the four faces this node is adjacent to, thereby providing all
possible neighbors.
"""
function populateNeighbors!(node, nodesByPosition, visitedFaces, costs, numSteinerPoints, bc::BoundaryConditions)
    @debug "populating neighbors of $(node.position) ($(length(node.neighbors)))"
    # for e in node.neighbors
    #     @debug "      $(e)"
    # end
    for face in faces(node.position)
        x, y = face
        X, Y = size(costs)

        if bc == PERIODIC
            face = (x, y) = (jmod(x, X), jmod(y, Y))
        end

        @debug "$(face) in $(visitedFaces): $(face in visitedFaces)"
        if x >= 1 && y >= 1 && x <= X && y <= Y && !(face in visitedFaces)
            push!(visitedFaces, face)
            exploreFace!(nodesByPosition, face, costs, numSteinerPoints, bc)
            @debug "exploring face $(face). faces explored: $(visitedFaces)"
        end
    end
    @debug "populated: $(node.position) ($(length(node.neighbors)))"
    # for e in node.neighbors
    #     @debug "      $(e)"
    # end
end

# nodesByPosition = Dict{Position, Node}((1., 1.) => Node((1., 1.)))
# visitedFaces = Set{Face}()
# tcosts = [2. 3. 1.; 1. 3. 1.; 1. 1. 1.]
# @test populateNeighbors!(nodesByPosition[(1., 1.)], nodesByPosition, visitedFaces, tcosts); true


"""
Divides original edges.
"""
function divideOriginalEdges!(nodesByPosition::Dict{Position,Node}, steinerPoints::Int64, bc, X, Y)
    for (_pos, source) in copy(nodesByPosition)
        for edge in copy(source.neighbors)
            # delete the originalEdge and add numSteinerPoints new originalEdges
            if edge.isOriginal
                delete!(source.neighbors, edge)
                subdivideEdge!(source, edge.node, edge.cost, nodesByPosition, steinerPoints, bc, X, Y)
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
    Paths.divideOriginalEdges!(doeNodes, 1, Paths.SOLID, 10, 10)
    @test doeNodes[(1.5, 1.0)].position == (1.5, 1.0)
    @test doeNodes[(1.0, 1.0)].neighbors == [Edge(doeNodes[(1.5, 1)], 4.0, true)]
    @test doeNodes[(1.5, 1.0)].neighbors == [Edge(doeNodes[(2, 1)], 4.0, true), Edge(doeNodes[(1, 1)], 4.0, true)]
    @test doeNodes[(2.0, 1.0)].neighbors == [Edge(doeNodes[(1.5, 1)], 4.0, true)]

    doeCopy = deepcopy(doeNodes)
    Paths.divideOriginalEdges!(doeNodes, 1, Paths.SOLID, 10, 10)

    Paths.divideOriginalEdges!(doeNodes, 1, Paths.SOLID, 10, 10)
    Paths.divideOriginalEdges!(doeCopy, 3, Paths.SOLID, 10, 10)
    @test doeCopy == doeNodes
end


function connectAcrossFaces!(nodesByPosition::Dict{Position,Node}, costs)
    nodesByFace = Dict{Face,Array{Node}}()
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


function resetNodes(sourceNode, path::Array{Node})
    nodesByPosition = Dict(sourceNode.position => sourceNode)
    for node in path
        # Add the nodes we already saw
        nodesByPosition[round.(node.position, sigdigits=DICT_SIGS)] = node
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


function heuristic(pos::Tuple{Number,Number}, target::Tuple{Number,Number})::Float64
    return 1.0 * norm(pos .- target)
end


"""
Returns distance on a 2d space with periodic boundaries
"""
function periodicNorm(p1, p2, X, Y)
    x1, y1 = p1
    x2, y2 = p2
    dx = min(abs(x2 - x1), X - abs(x2 - x1))
    dy = min(abs(y2 - y1), Y - abs(y2 - y1))
    return sqrt(dx^2 + dy^2)
end


"""
Main exported function of this file. Implements the any-directional search algorithm.
"""
function shortestPathKanaiSuzuki(
    source::Position, target::Position, costs::Matrix{Float64};
    bc::BoundaryConditions=SOLID, deltaThreshold=0.1, maxSteps=3,
    numSteinerPoints::Int64=3)::Tuple{Path,Float64}
    # TODO – switch these to rounding instead of flooring.
    # TODO – check to make sure these are inbounds?
    source = floor.(source)
    target = floor.(target)

    # @info "searching from $(source) to $(target)"

    nodesByPosition = Dict{Paths.Position,Node}(source => Node(source), target => Node(target))
    visitedFaces = Set{Paths.Face}()
    initialNeighbors = (node) -> (
        Paths.populateNeighbors!(node, nodesByPosition, visitedFaces, costs, numSteinerPoints, bc);
        return [(e.node, e.cost) for e in node.neighbors])


    X, Y = size(costs)

    if bc == SOLID
        heuristic = n -> norm(n.position .- target)
    elseif bc == PERIODIC
        heuristic = n -> periodicNorm(n.position, target, X, Y)
    else
        throw("unknown boundary condition $(bc)")
    end

    # Step 1 - construct G0 with nodesByPosition and edges
    # @debug "constructing original graph"
    # nodesByPosition, nodesByFace = constructOriginalGraph(costs)


    @debug "running initial search"
    # path = []
    # pathCost = Inf
    path, pathCost = astar(nodesByPosition[source], nodesByPosition[target], initialNeighbors, heuristic)
    @debug "initial astar search populated $(length(nodesByPosition)) nodesByPosition"

    # @info "found path of cost $(pathCost), $([p.position for p in path])"

    delta = Inf
    i = 1

    while delta > deltaThreshold && i < maxSteps
        # Remove unneeded nodesByPosition only after the first initial search.
        # TODO - actually remove unneeded nodesByPosition now.
        # if i > 1
        nodesByPosition = resetNodes(nodesByPosition[source], path)
        # end


        # Step 2 - construct G_{n+1}
        # Add steiner points
        # @info "adding steiner points"
        divideOriginalEdges!(nodesByPosition, numSteinerPoints, bc, X, Y)

        # @info "connecting edges"
        connectAcrossFaces!(nodesByPosition, costs)

        # @info "step $(i) – searching over $(length(nodesByPosition)) nodesByPosition"
        # Step 3 - a-star G_n
        neighbors = (n) -> [(e.node, e.cost) for e in n.neighbors]
        # h = n->norm(n.position .- nodesByPosition[target].position)
        path, newPathCost = astar(nodesByPosition[source], nodesByPosition[target], neighbors, heuristic)
        delta = pathCost - newPathCost
        pathCost = newPathCost
        i += 1
        # @info "found path of cost $(pathCost), $([p.position for p in path])"

    end

    # @info "returning path of cost $(pathCost), $([p.position for p in path])"
    # for p in path
    #     @debug "$(p.position)"
    #     # for e in p.neighbors
    #     #     @debug "      $(e)"
    #     # end
    # end

    return ([n.position for n in path], pathCost)
end


@testitem "Test shortestPathKanaiSuzuki" begin
    using Test, Paths, LinearAlgebra

    p, c = Paths.shortestPathKanaiSuzuki((1.0, 1.0), (3.0, 3.0), zeros(Float64, (10, 10)) .+ 1)
    @test length(p) == 3
    p, c = Paths.shortestPathKanaiSuzuki((3.0, 3.0), (1.0, 1.0), zeros(Float64, (10, 10)) .+ 1, numSteinerPoints=1)
    @test length(p) == 3

    # using Logging
    # debuglogger = ConsoleLogger(stderr, Logging.Debug)
    # with_logger(debuglogger) do
    p, c = Paths.shortestPathKanaiSuzuki((10.0, 10.0), (1.0, 1.0), zeros(Float64, (10, 10)) .+ 1, numSteinerPoints=1)
    @test length(p) == 10
    # end

    # These are broken because search goes from vertex to vertex only.
    # @test length(shortestPathKanaiSuzuki((1.0, 1.0), (1.5, 1.5), zeros(Float64, (2, 2)).+1, 1)) == 1
    # @test length(shortestPathKanaiSuzuki((1.0, 1.0), (1.5, 1.5), zeros(Float64, (2, 2)).+1, 2)) == 1
    # @test length(shortestPathKanaiSuzuki((1.5, 1.0), (1.5, 1.5), zeros(Float64, (2, 2)).+1, 2)) == 1


    δ = 0.01
    tolerance = 0.1
    p, c = Paths.shortestPathKanaiSuzuki((1.0, 1.0), (10.0, 10.0), zeros(Float64, (10, 10)) .+ 1,
        deltaThreshold=δ, numSteinerPoints=2)
    @test c ≈ norm((9, 9))
    p, c = Paths.shortestPathKanaiSuzuki((1.0, 1.0), (10.0, 10.0), zeros(Float64, (10, 10)) .+ 5, deltaThreshold=δ, numSteinerPoints=2)
    @test c ≈ 5 * norm((9, 9))
    p, c = Paths.shortestPathKanaiSuzuki((1.0, 1.0), (4.0, 5.0), zeros(Float64, (10, 10)) .+ 5, deltaThreshold=δ, numSteinerPoints=2)
    @test c - 5 * 5 < tolerance
    p, c = Paths.shortestPathKanaiSuzuki((2.0, 2.0), (5.0, 5.0),
        [
            1.0 1.0 1.0 1.0 1.0;
            1.0 5.0 5.0 5.0 5.0;
            1.0 5.0 5.0 5.0 5.0;
            1.0 5.0 5.0 5.0 5.0;
            1.0 1.0 1.0 1.0 1.0
        ])
    @test c ≈ 6.0


    using Logging
    debuglogger = ConsoleLogger(stderr, Logging.Debug)
    # with_logger(debuglogger) do
    # Periodic boundary conditions search
    p, c = Paths.shortestPathKanaiSuzuki((1.0, 1.0), (5.0, 5.0), zeros(Float64, (5, 5)) .+ 1,
        deltaThreshold=δ, numSteinerPoints=0, bc=Paths.PERIODIC)
    @test c ≈ norm((1, 1))
    # end


    p, c = Paths.shortestPathKanaiSuzuki((1.0, 1.0), (5.0, 5.0), zeros(Float64, (5, 5)) .+ 1,
        deltaThreshold=δ, numSteinerPoints=0, bc=Paths.PERIODIC)
    @test c ≈ norm((1, 1))

    # wraps around the corner; distance should be sqrt(2)
    p, c = Paths.shortestPathKanaiSuzuki((1.0, 1.0), (5.0, 5.0), zeros(Float64, (5, 5)) .+ 10,
        deltaThreshold=δ, numSteinerPoints=0, bc=Paths.PERIODIC)
    @test c ≈ norm((1, 1)) * 10

    # with_logger(debuglogger) do
    p, c = Paths.shortestPathKanaiSuzuki((2.0, 2.0), (5.0, 5.0), zeros(Float64, (5, 5)) .+ 10,
        deltaThreshold=δ, numSteinerPoints=1, bc=Paths.PERIODIC)
    @test c ≈ norm((2, 2)) * 10
    # end
end
