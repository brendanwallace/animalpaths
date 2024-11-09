"""
Contains some core data types and Simulation class.
"""
abstract type Updatable end
abstract type Walker <: Updatable end
abstract type AbstractWorld <: Updatable end

"""
A cannonical position in Euclidean space, e.g. an (x, y)
coordinate.
"""
const Position = Tuple{Float64,Float64}

"""
GridPosition is an (x, y) coordinate pair used to index into
a World's grid of patches.

This is *not* necessarily a position in Euclidean space; it should
be treated as a reference to a patch. If the World is using the hexagonal
layout, for example, these do not map exactly to Euclidean coordinates.

In a Square World, these kind of map to the bottom-left corner of a patch.
"""
const GridPosition = Tuple{Integer,Integer}
# const Vector = Tuple{Float64, Float64}

"""
Path defines a set of steps that a walker takes across the world
from a defined start Location to an end Location.

These are kept minimal/simple. The function that computes a best path
should also return the sum cost of the path, and callers can compute
the length of the path by simply adding up the distances between Positions.
"""
const Path = Array{Position}

struct Location
    position::Tuple{Float64,Float64}
end


function update!(u::Updatable)
    @error "No update! function implemented for this type"
end


mutable struct Simulation <: Updatable
    settings::Settings
    world::AbstractWorld
    walkers::Array{Walker}
    locations::Array{Location}
    steps::Integer

    Simulation() = new()
end


function update!(sim::Simulation)
    for w in sim.walkers
        update!(w)
    end
    update!(sim.world)
    sim.steps += 1
end

