# """
# Search implements the continuous search algorithm.
# """
using DataStructures: LinkedList, cons, nil, PriorityQueue, enqueue!, dequeue!, DefaultDict
using Test, TestItems
using LinearAlgebra: norm


# include("common.jl")


# This is the bottom-left corner of the square face.
const Face = GridPosition

abstract type _Edge end

struct Node
    position::Position
    neighbors::Vector{_Edge}
    # faces :: Vector{Face}
end

Node(pos) = Node(pos, [])

Base.show(io::IO, n::Node) = print(io, "{$(n.position)}")


function faces(pos::Position)::Array{Face}
    δ = 0.001
    x, y = pos
    if mod(x, 1) == 0 && mod(y, 1) == 0
        return [Int64.(p) for p in [(x, y), (x - 1, y), (x, y - 1), (x - 1, y - 1)]]
    elseif mod(x, 1) == 0
        return [Int64.(floor.(p)) for p in [(x, y), (x - 1, y)]]
    elseif mod(y, 1) == 0
        return [Int64.(floor.(p)) for p in [(x, y), (x, y - 1)]]
    else
        return [Int64.(floor.(pos))]
    end
end


function faces(node::Node)::Array{Face}
    return faces(node.position)
end


# Otherwise == just sees that the array pointers are different and calls the
# structs different.
# Uncommenting the neighbor comparison lets us do deep equality testing by default.
Base.:(==)(x::Node, y::Node) = x.position == y.position #&& sort(x.neighbors) == sort(y.neighbors)


struct Edge <: _Edge
    node::Node
    cost::Float64
    isOriginal::Bool
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

include("astar.jl")
include("kanaisuzuki.jl")
include("gridsearch.jl")