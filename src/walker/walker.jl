const WALKER_SPEED = 1.0



"""
Assigns a walker a new target, to be called after a walker arrives.

This should stay the same for all the walker types.

As this grows, it can maybe turn into more of a dispatch to other functions.
"""
function newtarget!(walker::Walker)
    scenario::Scenario = walker.simulation.settings.scenario
    if scenario ∈ [RANDOM_FIXED, TRIANGLE]
        walker.target = rand(walker.simulation.locations)
    elseif scenario == RANDOM_DYNAMIC
        prevTarget = walker.target
        if !(prevTarget isa Nothing)
            delete!(walker.simulation.locations, prevTarget)
        end
        walker.target = Location(random_pos(walker.simulation.settings))
        push!(walker.simulation.locations, walker.target)
    elseif scenario == CENTRAL_PLACE
        # the shared-home position is walker.simulations.locations[1]
        prevTarget = walker.target
        # initial target is always Nothing.
        if (prevTarget isa Nothing)
            walker.target = walker.simulation.locations[1]
        # if we're at the shared-home position
        elseif (prevTarget == walker.simulation.locations[1])
            # new random target along the periphery
            walker.target = Location(newPeripheryLocation(walker.simulation.settings))
            push!(walker.simulation.locations, walker.target)
        else
            # clean up this location; go back to the home location
            delete!(walker.simulation.locations, prevTarget)
            walker.target = walker.simulation.locations[1]
        end
    elseif scenario == WALL_TO_WALL
        prevTarget = walker.target
        # Walker's initial target is always Nothing.
        # Here we send them to the left wall (pos[1] = 1) to start, or if their
        # previous target was right wall (pos[1] = X).
        if (prevTarget isa Nothing) || (prevTarget.position[1] == float(walker.simulation.settings.X))
            walker.target = Location(
                (1.0,
                (rand() * (walker.simulation.settings.Y - 1)) + 1))
        else
        # Otherwise we send them to the right wall.
            walker.target = Location(
                (float(walker.simulation.settings.X),
                (rand() * (walker.simulation.settings.Y - 1)) + 1))
        end
        push!(walker.simulation.locations, walker.target)
        if !(prevTarget isa Nothing)
            delete!(walker.simulation.locations, prevTarget)
        end
    else
        throw("scenario not found for newtarget!")
    end
end

"""
This is for the SHARED_HOME scenario.
"""
function newPeripheryLocation(settings::Settings)::Position
    # We assume that settings.X = settings.Y
    @assert settings.X == settings.Y
    radius = (settings.X - 1) / 2

    center = (radius, radius)
    randomDirection = rand() * 2 * pi
    randomPosition = (1, 1) .+ center .+ (radius .* (cos(randomDirection), sin(randomDirection)))
end


include("searchwalker.jl")


include("stepwalker.jl")
