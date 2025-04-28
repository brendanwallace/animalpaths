
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

function squareneighbors(position::GridPosition, X=nothing, Y=nothing)::Array{GridPosition}
    x, y = position
    neighbors = [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    if X !== nothing && Y !== nothing
        neighbors = [(jmod(n[1], X), jmod(n[2], Y)) for n in neighbors]
    end
    return neighbors
end

@testitem "test square neighbors" begin


end

"""
Returns an array of the neighbors of `position` and the costs to get there.

This assumes you can move in 12 directions. 6 in the normal hex-neighborhood directions,
and 6 more along the edges between the immediate neighbors.


"""
# function hex_plus_neighbors_costs(position:GridPosition, world::World)::Array{Tuple{GridPosition,Float64}}

#     return []
# end





function gridSearch(
    source::Position, target::Position, world::World, searchStrategy::SearchStrategy)::Tuple{Path,Float64}
    # if we're walking on a constrained grid, search should reflect it
    if searchStrategy == GRID_WALK_HEX
        neighbors = (cp) -> [(p, costAt(world, p)) for p in hexneighbors(cp)]
    elseif searchStrategy == GRID_WALK_NEUMANN
        neighbors = (cp) -> [(p, costAt(world, p)) for p in squareneighbors(cp)]
    elseif searchStrategy == GRID_WALK_MOORE
        neighbors = (cp) -> [(p, costAt(world, p)) for p in mooreneighbors(cp)]
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

