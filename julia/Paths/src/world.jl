const DIFFUSION_RADIUS = 3
const DIFFUSION_GAUSSIAN_VARIANCE = 1.0
const τ = 2*π

@enum PatchLogic begin
	Linear
	Logistic
	Saturating
end

struct World <: AbstractWorld
    X::Int
    Y::Int
    maxCost::Float64
    simulation # :: Simulation
    # Measures the amount a patch has improved. 0 is no improvement.
    patches::Array{Float64}
    improvementLogic::PatchLogic
    recoveryLogic::PatchLogic
    World(x, y, maxCost, simulation, improvementLogic, recoveryLogic) = new(
    	x, y, maxCost, simulation, zeros(Float64, (x, y)), improvementLogic, recoveryLogic)
end


function update!(world :: World)
	r = world.simulation.patchRecovery 

	if world.recoveryLogic == Linear
		world.patches .-= r
	elseif world.recoveryLogic == Saturating
		world.patches .-= (r .* (1 .- world.patches))
	elseif world.recoveryLogic == Logistic
		world.patches .-= (r .* (1 .- world.patches) .* world.patches)
	end

	world.patches .= clamp!(world.patches, 0.0, 1.0)
end



function costs(world::AbstractWorld)
    return world.maxCost .* (1.0 .- world.patches) .+ (1.0 .* world.patches)
end


function _improvePatch!(world, x::Int, y::Int, improvement::Float64)
	r = improvement

	# It's necessary to add this, otherwise improvement=0 becomes an absorbing state.
	ϵ = 0.1

	if world.improvementLogic == Linear
		world.patches[x, y] += r
	elseif world.improvementLogic == Saturating
		world.patches[x, y] += (r * (1 - world.patches[x, y]))
	elseif world.improvementLogic == Logistic
		world.patches[x, y] += (r * (1 - world.patches[x, y]) * (world.patches[x, y] + ϵ))
	end

end

function gaussianDiffusion(μ, σ2, dx, dy)
	return μ * 1/sqrt((τ * σ2)) * ℯ^(-(1/2) * (dx^2 + dy^2) / σ2)
end

@testitem "test gaussianDiffusion" begin

@test Paths.gaussianDiffusion(1, 1, 0, 0) ≈ 1 / sqrt(2 * π)
@test Paths.gaussianDiffusion(1, 1, 1, 1) < Paths.gaussianDiffusion(1, 1, 0, 0)
# Higher variance -> larger values far away from center
@test Paths.gaussianDiffusion(1, 1, 10, 10) < Paths.gaussianDiffusion(1, 2, 10, 10)

end

function improvePatch!(world, gridPosition::GridPosition, weight)
	r = DIFFUSION_RADIUS
	x, y = gridPosition
	# _improvePatch!(world, x, y, weight*world.simulation.patchImprovement)
	for dx in -r:r
		for dy in -r:r
			_x, _y = x + dx, y + dy
			if _x >= 1 && _x <= world.X && _y >= 1 && _y <= world.Y
				improvementValue = weight * gaussianDiffusion(
					world.simulation.patchImprovement, DIFFUSION_GAUSSIAN_VARIANCE, dx, dy)
				_improvePatch!(world, _x, _y, improvementValue)
			end
		end
	end
end
