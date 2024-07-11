const DIFFUSION_RADIUS = 3
const DIFFUSION_GAUSSIAN_VARIANCE = 2.0
const τ = 2*π

struct World <: AbstractWorld
    X::Int
    Y::Int
    simulation :: Simulation
    patches::Array{Float64}
    World(x, y, simulation) = new(x, y, simulation, zeros(Float64, (x, y)))
end

function update!(world :: World)
	world.patches .-= world.simulation.patchRecovery
	world.patches .= clamp!(world.patches, 0.0, 1.0) 
end


function _improvePatch!(world, x::Int, y::Int, improvement::Float64)
	world.patches[x, y] += improvement
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
