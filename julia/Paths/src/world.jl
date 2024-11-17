const τ = 2 * π


struct World <: AbstractWorld
    settings::Settings

    # Measures the amount a patch has improved. 0 is no improvement.
    patches::Array{Float64}

    # Main entry point to making a new ContinuousGridWorld struct.
    World(settings) = new(settings, zeros(Float64, (settings.X, settings.Y)))
end


"""
Update only has to recover patches. Improvement happens from walkers calling
into improvePatch.
"""
function update!(world::AbstractWorld)
    r = world.settings.patchRecovery
    if world.settings.recoveryLogic == LINEAR
        world.patches .-= r
    elseif world.settings.recoveryLogic == SATURATING
        world.patches .-= (r .* (1 .- world.patches))
    elseif world.settings.recoveryLogic == LOGISTIC
        world.patches .-= (r .* (1 .- world.patches) .* world.patches)
    end

    world.patches .= clamp!(world.patches, 0.0, 1.0)
end


"""
Returns the comfort [0-1] at a spot on the world, 0 being least comfortable
and 1 being most comfortable.

Assumes spots outside of the world have a comfort of 0.
"""
function comfortAt(world::AbstractWorld, x::Int, y::Int)::Float64
    if x <= 0 || y <= 0 || x > world.settings.X || y > world.settings.Y
        return 0.0
    else
        # Comfort is, by definition, raw patch improvement.
        return world.patches[x, y]
    end
end

function costAt(world::AbstractWorld, x::Int, y::Int)::Float64
    if x <= 0 || y <= 0 || x > world.settings.X || y > world.settings.Y
        # Out-of-bounds is infinite cost.
        return Inf
    else
        return world.settings.maxCost * (1.0 - world.patches[x, y]) + (1.0 * world.patches[x, y])
    end
end

function costAt(world::AbstractWorld, p::GridPosition)::Float64
    x, y = p
    return costAt(world, x, y)
end

# """
# Allows for raw access, so needs to check X, Y bounds.
# """
# function costAt(costs::Array{Float64}, p::GridPosition)::Float64
#     x, y = p
#     return costs[x, y]
# end


function costs(world::AbstractWorld)::Array{Float64}
    return world.settings.maxCost .* (1.0 .- world.patches) .+ (1.0 .* world.patches)
end

"""
Private method that just applies raw improvement. Outside callers should use
improvePatch! to properly apply diffusion.
"""
function _improvePatch!(world::AbstractWorld, x::Int, y::Int, improvement::Float64)
    r = improvement

    # It's necessary to add this, otherwise improvement=0 becomes an absorbing state.
    ϵ = 0.1

    if world.settings.improvementLogic == LINEAR
        world.patches[x, y] += r
    elseif world.settings.improvementLogic == SATURATING
        world.patches[x, y] += (r * (1 - world.patches[x, y]))
    elseif world.settings.improvementLogic == LOGISTIC
        world.patches[x, y] += (r * (1 - world.patches[x, y]) * (world.patches[x, y] + ϵ))
    end
end

"""
Util function for computing 2d gaussian.
"""
function gaussianDiffusion(μ, σ2, dx, dy)
    if σ2 == 0.0
        if dx == 0 && dy == 0
            return μ
        else
            return 0.0
        end
    end
    return μ * 1 / sqrt((τ * σ2)) * ℯ^(-(1 / 2) * (dx^2 + dy^2) / σ2)
end

@testitem "test gaussianDiffusion" begin

    @test Paths.gaussianDiffusion(1, 1, 0, 0) ≈ 1 / sqrt(2 * π)
    @test Paths.gaussianDiffusion(1, 1, 1, 1) < Paths.gaussianDiffusion(1, 1, 0, 0)
    # Higher variance -> larger values far away from center
    @test Paths.gaussianDiffusion(1, 1, 10, 10) < Paths.gaussianDiffusion(1, 2, 10, 10)

end


"""
Applies gaussian diffusion of the improvement in a small neighborhood around
the targetted grid position.
"""
function improvePatch!(world::World, gridPosition::GridPosition, weight)
    r = world.settings.diffusionRadius
    x, y = gridPosition
    # _improvePatch!(world, x, y, weight*world.simulation.patchImprovement)
    if world.settings.gridType == SQUARE_WORLD
        for dx in -r:r
            for dy in -r:r
                _x, _y = x + dx, y + dy
                if _x >= 1 && _x <= world.settings.X && _y >= 1 && _y <= world.settings.Y
                    improvementValue = weight * gaussianDiffusion(
                        world.settings.patchImprovement, world.settings.diffusionGaussianVariance, dx, dy)
                    _improvePatch!(world, _x, _y, improvementValue)
                end
            end
        end
    elseif world.settings.gridType == HEX_WORLD
        for r in 0:world.settings.diffusionRadius
            for (_x, _y) in hexneighbors(x, y, r)
                if _x >= 1 && _x <= world.settings.X && _y >= 1 && _y <= world.settings.Y
                    improvementValue = weight * gaussianDiffusion(
                        world.settings.patchImprovement, world.settings.diffusionGaussianVariance, 0, r)
                    _improvePatch!(world, _x, _y, improvementValue)
                end
            end
        end
        # TODO - consider implementing diffusion on the hex world.
        # _improvePatch!(world, x, y, weight * world.settings.patchImprovement)
    else
        throw("unknown grid type $(world.settings.gridType)")
    end
end
