
# TODO - is this being used in more than just walker?
function normalize(x)
    n = norm(x)
    if n > 0
        return x ./ n
    else
        return x
    end
end


# It's wild that this doesn't already exist.
function delete!(array, element)
    deleteat!(array, findall(isequal(element), array))
end

function floortogrid(p::Tuple{Float64,Float64})::Tuple{Integer,Integer}
    return Integer.(floor.(p))
end

@testitem "Test floor to grid" begin
    using Test, Paths
    @test Paths.floortogrid((1.0, 1.0)) == (1, 1)
    @test Paths.floortogrid((1.1, 3.0)) == (1, 3)
    @test Paths.floortogrid((10.9999, 3.444)) == (10, 3)
end

function roundtogrid(p::Tuple{Float64,Float64})::Tuple{Integer,Integer}
    return Integer.(round.(p))
end

@testitem "Test round to grid" begin
    using Test, Paths
    @test Paths.roundtogrid((1.0, 1.0)) == (1, 1)
    @test Paths.roundtogrid((1.1, 3.0)) == (1, 3)
    @test Paths.roundtogrid((10.9999, 3.444)) == (11, 3)
end


function hexneighbors(x::Integer, y::Integer, r::Integer)::Array{Tuple{Integer,Integer}}
    if r == 0
        return [(x, y)]
    elseif r == 1
        neighbors::Array{Tuple{Integer,Integer}} = [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
        if mod(y, 2) == 1 # odd rows
            push!(neighbors, (x + 1, y + 1))
            push!(neighbors, (x + 1, y - 1))
        else # even rows
            push!(neighbors, (x - 1, y + 1))
            push!(neighbors, (x - 1, y - 1))
        end
        @assert length(neighbors) == 6
        return neighbors
    elseif r >= 2
        @debug "hexNeighborsAtDistance not implemented for r>=2: r=$(r)"
        return []
    end
end

@testitem "Test hexneighbors" begin
    using Test, Paths
    @test Paths.hexneighbors(0, 0, 0) == [(0, 0)]
    @test Paths.hexneighbors(1, 1, 0) == [(1, 1)]
    # odd row
    @test Paths.hexneighbors(1, 1, 1) == [(2, 1), (0, 1), (1, 2), (1, 0), (2, 2), (2, 0)]
    # even rows
    @test Paths.hexneighbors(2, 2, 1) == [(3, 2), (1, 2), (2, 3), (2, 1), (1, 3), (1, 1)]
    @test Paths.hexneighbors(1, 2, 1) == [(2, 2), (0, 2), (1, 3), (1, 1), (0, 3), (0, 1)]
end


function rotate(vector, angle)
    rotation_matrix = [
        cos(angle) -sin(angle);
        sin(angle) cos(angle)]
    rotated = rotation_matrix * [vector[1]; vector[2]]
    return (rotated[1], rotated[2])
end


@testitem "test periodic norm" begin
    using Test, Paths
    @test Paths.periodicNorm([0, 1], [0, 2], 10, 10) == 1
    # wraps the y coordinate around
    @test Paths.periodicNorm([0, 1], [0, 9], 10, 10) == 2
    # wraps the x coordinate around
    @test Paths.periodicNorm([1, 0], [9, 0], 10, 10) == 2
    # wraps around the corner
    @test Paths.periodicNorm([1, 1], [10, 10], 10, 10) ≈ sqrt(2)
end


"""
Julia indexes by 1, so we have to adjust mods like this.
"""
function jmod(num::Number, base)
    return 1 + mod(num - 1, base)
end

function jmod(nums::Tuple{Number,Number}, bases::Tuple{Number,Number})
    x, y = nums
    X, Y = bases
    return (jmod(x, X), jmod(y, Y))
end


@testitem "test jmod" begin
    using Test, Paths
    @test Paths.jmod(10, 10) == 10
    @test Paths.jmod(3.5, 10) == 3.5
    @test Paths.jmod(9.9, 10) == 9.9
    @test Paths.jmod(0.5, 10) == 10.5
end