using TestItems
using Test
using Plots
using Random
using LinearAlgebra

const DEFAULT_L = 300::Int
const NUM_LOCATIONS = 10
const NUM_WALKERS = 10
const ARRIVAL_DISTANCE = 1.0
const WALKER_SPEED = 1.0
const PATCH_IMPROVEMENT = 0.2
const PATCH_RECOVERY = 0.

const DIFFUSION_RADIUS = 3
const DIFFUSION_GAUSSIAN_VARIANCE = 2.0

normalize(x) = x / norm(x)

abstract type Walker end


struct Location
    pos :: Vector{Float64}
end


struct World
    X::Int
    Y::Int
    patches::Array{Float64}
    World(x, y) = new(x, y, zeros(Float64, (x, y)))
end

# Might make this concrete in this file
struct Scenario
	locations
	walkers
end

mutable struct Simulation
	world :: World
	walkers :: Array{Walker}
	locations :: Array{Location}
	scenario :: Scenario
    Simulation(scenario) = (
    	sim = new();
    	sim.world = World(DEFAULT_L, DEFAULT_L);
    	sim.walkers = scenario.walkers(sim);
    	sim.locations = scenario.locations(sim);
    	sim.scenario = scenario;
    	sim
	)
end


mutable struct DirectWalker <: Walker
	sim :: Simulation
	target :: Union{Location, Nothing}
	pos :: Vector{Float64}
end

function random_pos(sim)
	return rand(2).*[sim.world.X, sim.world.Y].+1
end

function default_locations(sim::Simulation) :: Array{Location}
	return [Location(random_pos(sim)) for i in 1:NUM_LOCATIONS]
end

function default_walkers(sim::Simulation) :: Array{Walker}
	return [DirectWalker(sim, nothing, random_pos(sim)) for i in 1:NUM_WALKERS]
end

DEFAULT_SCENARIO::Scenario = Scenario(default_locations, default_walkers)


function update!(sim :: Simulation)
	for w in sim.walkers
		update!(w)
	end
	update!(sim.world)
end

function update!(walker :: Walker)
	@error "No update! function implemented for this walker class"
end


function update!(walker :: DirectWalker)
	if walker.target isa Nothing
		walker.target = rand(walker.sim.locations)
	end
	arrived = norm(walker.pos - walker.target.pos) <= ARRIVAL_DISTANCE
	if arrived
		walker.target = rand(walker.sim.locations)
	else
		direction = normalize(walker.target.pos - walker.pos)
		walker.pos += direction * WALKER_SPEED
		improvePatch!(walker.sim.world, walker.pos)
	end
end

function update!(world :: World)
	world.patches .-= PATCH_RECOVERY
	world.patches .= clamp!(world.patches, 0.0, 1.0) 
end


function _improvePatch!(world, x::Int, y::Int, improvement::Float64)
	world.patches[x, y] += improvement
end

function gaussianDiffusion(μ, σ2, dx, dy)
	return μ * 1/(2 * π * σ2) * ℯ^(-(dx^2 + dy^2) / (2 * σ2))
end

@test gaussianDiffusion(1, 1, 0, 0) ≈ 1 / (2 * π)
@test gaussianDiffusion(1, 1, 1, 1) < gaussianDiffusion(1, 1, 0, 0)
# Higher variance -> larger values far away from center
@test gaussianDiffusion(1, 1, 10, 10) < gaussianDiffusion(1, 2, 10, 10)

function improvePatch!(world, pos)
	r = DIFFUSION_RADIUS
	x, y = Int.(floor.(pos))
	for dx in -r:r
		for dy in -r:r
			_x, _y = x + dx, y + dy
			if _x >= 1 && _x <= world.X && _y >= 1 && _y <= world.Y
				improvementValue = gaussianDiffusion(PATCH_IMPROVEMENT, DIFFUSION_GAUSSIAN_VARIANCE, dx, dy)
				_improvePatch!(world, _x, _y, improvementValue)
			end
		end
	end
end



sim = Simulation(DEFAULT_SCENARIO)
@test sim isa Simulation
update!(sim)
@test sim isa Simulation


@testitem "simulation sanity check" begin
	using Paths
	using Test
	using DataStructures

	sim = Paths.Simulation(Paths.GridWorld(), [], [], Paths.GridScenario())
	@test sim == sim
end
