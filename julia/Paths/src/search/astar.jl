
"""
Basic generic astar implementation.
"""
function astar(start::T, goal::T, neighbors::Function, h::Function)::Tuple{Array{T},Float64} where {T}

    bestCost = DefaultDict{T,Float64}(Inf)
    pq = PriorityQueue{T,Float64}()
    cameFrom = Dict{T,T}()

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
                if haskey(cameFrom, current)
                    current = cameFrom[current]
                    push!(path, current)
                else
                    @warn "failed to find a path from $(start) to $(goal)"
                    @warn "$(current) not in $(cameFrom)"
                    @warn "returning $(reverse(path))"
                    break
                end
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
