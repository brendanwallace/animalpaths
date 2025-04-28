
NUM_ANGLES = 30

"""
HeuristicWalker conservatively considers steps in different directions

"""
mutable struct HeuristicWalker <: Walker
    simulation::Simulation
    target::Union{Location,Nothing}
    position::Position
end


function update!(walker::HeuristicWalker)
    if walker.target isa Nothing || arrived(walker)
        newtarget!(walker)
    end

    targetDirection = normalize(walker.target.position .- walker.position)

    bestStep = walker.position .+ (targetDirection .* WALKER_SPEED)
    bestCost = costAt(walker.simulation.world, roundtogrid(bestStep)) +
               norm(walker.target.position .- bestStep) * walker.simulation.settings.maxCost

    for angleDiff ∈ -π/2:π/NUM_ANGLES:π/2

        stepDirection = rotate(targetDirection, angleDiff)
        step = walker.position .+ stepDirection
        cost = costAt(walker.simulation.world, roundtogrid(step)) +
               norm(walker.target.position .- step) * walker.simulation.settings.maxCost

        # println("t$(walker.target.position) angle$(angleDiff) sd$(stepDirection) cost $(cost)")

        if cost < bestCost
            bestStep = step
            bestCost = cost
        end
    end

    # println("target: $(walker.target.position) bestStep $(bestStep)")

    walker.position = bestStep
    improvePatch!(walker.simulation.world, roundtogrid(walker.position), 1.0)

end
