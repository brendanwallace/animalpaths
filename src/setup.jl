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
    if settings.searchStrategy ∈ SEARCH_WALKS
        w = SearchWalker
    elseif settings.searchStrategy ∈ STEP_WALKS
        w = StepWalker
    else
        throw("unhandled search strategy in function randomWalkers(): $(settings.searchStrategy)")
    end

    return [w(simulation, nothing, random_pos(settings)) for i in 1:settings.numWalkers]
end


function MakeSimulation(settings::Settings)::Simulation


    sim = Simulation()
    sim.settings = settings
    sim.world = World(settings)

    # Setup locations
    Random.seed!(settings.randomSeedLocations)
    if settings.scenario == RANDOM_FIXED
        sim.locations = randomLocations(settings)
    elseif settings.scenario == RANDOM_DYNAMIC
        sim.locations = []
    elseif settings.scenario == TRIANGLE
        sim.locations = [Location((5.0, 5.0)), Location((20.0, 5.0)), Location((35.0, 5.0 + sqrt(3) * 15.0))]
    else
        throw("unhandled scenario $(settings.scenario)")
    end


    # Setup walkers
    # This should guarantee the same starting locations, walker positions, and
    # initial targets.
    Random.seed!(settings.randomSeedWalkers)
    sim.walkers = randomWalkers(settings, sim)


    sim.steps = 0
    return sim
end
