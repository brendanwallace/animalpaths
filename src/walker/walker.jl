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
    else
        throw("scenario not found for newtarget!")
    end
end


include("searchwalker.jl")


include("stepwalker.jl")
