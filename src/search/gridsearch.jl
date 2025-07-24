
"""
hexneighbors returns the 6 neighbors of a hex position.

Odd rows are shifted forward, so they're connected to their upper-right and lower-right diagonal neighbors.
Even rows are shifted backward, so they're connected to their upper-left and lower-left diagonal neighbors.
"""
function hexneighbors(position::GridPosition)::Array{GridPosition}
    x, y = position
    neighbors = hexneighbors(x, y, 1)
    # neighbors::Array{Tuple{Integer,Integer}} = [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    # if mod(x, 2) == 1 # odd rows
    #     push!(neighbors, (x + 1, y + 1))
    #     push!(neighbors, (x + 1, y - 1))
    # else # even rows
    #     push!(neighbors, (x - 1, y + 1))
    #     push!(neighbors, (x - 1, y - 1))
    # end
    @assert length(neighbors) == 6
    return neighbors
end

"""
Returns the four neighbors in the Von Neumann neighborhood (up, down, left, right).
"""
function squareneighbors(position::GridPosition, X=nothing, Y=nothing)::Array{GridPosition}
    x, y = position
    neighbors = [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    if X !== nothing && Y !== nothing
        neighbors = [(jmod(n[1], X), jmod(n[2], Y)) for n in neighbors]
    end
    return neighbors
end

@testitem "test square neighbors" begin
    using Test, Paths

end



"""
Returns the 8 neighbors in the Moore neighborhood.
"""
function mooreneighbors(position::GridPosition, X=nothing, Y=nothing)::Array{GridPosition}
    x, y = position
    neighbors = [
        (x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1),
        (x + 1, y + 1), (x + 1, y - 1), (x - 1, y  + 1), (x - 1, y - 1),
    ]
    if X !== nothing && Y !== nothing
        neighbors = [(jmod(n[1], X), jmod(n[2], Y)) for n in neighbors]
    end
    return neighbors
end


function gridneighbors8(position::GridPosition, world::World, bc::BoundaryConditions, X, Y
    )::Array{Tuple{GridPosition, Float64}}
    x, y = position
    straight = [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    diagonal = [(x + 1, y + 1), (x + 1, y - 1), (x - 1, y  + 1), (x - 1, y - 1)]


    neighbors::Array{Tuple{GridPosition, Float64}} = []
    for (ps, distance) in [(straight, 1.0), (diagonal, sqrt(2.0))]
        for p in ps
            if bc == PERIODIC
                p = (jmod(p[1], X), jmod(p[2], Y))
            end
            cost = distance * costAt(world, p)
            push!(neighbors, (p, cost))
        end
    end
    return neighbors
end


@testitem "test moore neighbors" begin
    using Test, Paths
    @test issetequal(Set(Paths.mooreneighbors((10, 10))), Set(
        [(11, 10), (9, 10), (10, 11), (10, 9), (11, 11), (11, 9), (9, 11), (9, 9)]
    ))
end

"""
Returns an array of the neighbors of `position` and the costs to get there.

This assumes you can move in 12 directions. 6 in the normal hex-neighborhood directions,
and 6 more along the edges between the immediate neighbors.


"""
# function hex_plus_neighbors_costs(position:GridPosition, world::World)::Array{Tuple{GridPosition,Float64}}

#     return []
# end


function distance(cp :: Tuple{Int64, Int64}, p :: Tuple{Int64, Int64})::Float64 
    return sqrt((cp[1] - p[1])^2 + (cp[2] - p[2])^2)
end



function gridSearch(
    source::Position, target::Position, world::World, searchStrategy::SearchStrategy,
    bc::BoundaryConditions, X::Int, Y::Int)::Tuple{Path,Float64}
    # if we're walking on a constrained grid, search should reflect it
    if searchStrategy == GRID_WALK_HEX
        neighbors = (cp) -> [(p, costAt(world, p)) for p in hexneighbors(cp)]
    elseif searchStrategy == GRID_WALK_NEUMANN
        neighbors = (cp) -> [(p, costAt(world, p)) for p in squareneighbors(cp)]
    elseif searchStrategy == GRID_WALK_MOORE
        neighbors = (cp) -> gridneighbors8(cp, world, bc, X, Y)
        # neighbors = (cp) -> [(p, costAt(world, p) * distance(cp, p)) for p in mooreneighbors(cp)]
    elseif searchStrategy == GRID_WALK_HEX_PLUS
        throw("not implemented")
    else
        throw("search strategy not recognized as a grid search $(searchStrategy)")
    end

    heuristic = (p) -> norm(p .- roundtogrid(target))

    gridPath::Array{GridPosition}, cost = astar(
        roundtogrid(source), roundtogrid(target), neighbors, heuristic)
    path = [Float64.(p) for p in gridPath]
    return (path, cost)

end

