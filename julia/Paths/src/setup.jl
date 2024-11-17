"""
Routes settings to construct a Simulation object.
"""

"""
TODO – this should always stay in-bounds.
"""
function random_pos(settings::Settings)::Tuple{Float64,Float64}
    return Tuple(rand(2) .* [settings.X - 1, settings.Y - 1] .+ 1)
end


function randomLocations(settings::Settings)::Array{Location}
    return [Location(random_pos(settings)) for i in 1:settings.numLocations]
end


function randomWalkers(settings::Settings, simulation::Simulation)::Array{Walker}
    if settings.searchStrategy == KANAI_SUZUKI
        w = SearchWalker
    elseif settings.searchStrategy == GRADIENT_WALKER
        w = GradientWalker
    elseif settings.searchStrategy == GRID_WALK
        w = GridWalker
    elseif settings.searchStrategy == DIRECT_SEARCH
        w = DirectWalker
    else
        throw("unhandled search strategy in function randomWalkers(): $(settings.searchStrategy)")
    end

    return [w(simulation, nothing, random_pos(settings)) for i in 1:settings.numWalkers]
end


function MakeSimulation(settings::Settings)::Simulation
    # This should guarantee the same starting locations and walker positions.
    Random.seed!(settings.randomSeed)

    sim = Simulation()
    sim.settings = settings
    sim.world = World(settings)
    sim.walkers = randomWalkers(settings, sim)
    if settings.scenario == RANDOM_FIXED
        sim.locations = randomLocations(settings)
    else
        sim.locations = []
    end
    sim.steps = 0
    return sim
end
