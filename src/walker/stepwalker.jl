"""
Controls the number of directions the heuristic walker considers between
-90 degrees and +90 degrees of its target.

"""
HEURISTIC_NUM_ANGLES = 30

const Direction = Tuple{Float64, Float64}


mutable struct StepWalker <: Walker
    simulation::Simulation
    target::Union{Location,Nothing}
    position::Tuple{Float64,Float64}
end


function update!(walker::StepWalker)
    if walker.target isa Nothing
        newtarget!(walker)
    end
    arrived = norm(walker.position .- walker.target.position) <= WALKER_SPEED
    if arrived
        newtarget!(walker)
    else
        directionToStep = direction(walker)
        walker.position = walker.position .+ (directionToStep .* WALKER_SPEED)
        improvePatch!(walker.simulation.world, roundtogrid(walker.position), 1.0)
    end
end


function direction(walker::StepWalker)
    strategy = walker.simulation.settings.searchStrategy
    if strategy == DIRECT_WALK
        return normalize(walker.target.position .- walker.position)

    elseif strategy == GRADIENT_WALK
        return gradientDirection(walker)

    elseif strategy == HEURISTIC_WALK
        return heuristicDirection(walker.position, walker.target.position,
            p -> costAt(walker.simulation.world, roundtogrid(p)),
            walker.simulation.settings.maxCost,
            HEURISTIC_NUM_ANGLES,
            WALKER_SPEED)
    end
end 


function gradientDirection(walker::StepWalker)
    targetDirection = normalize(walker.target.position .- walker.position)
    comfortDirection = normalize(gradientAt(walker.position, walker.simulation.world))
    cw = walker.simulation.settings.comfortWeight
    return normalize(cw .* comfortDirection .+ (1.0 - cw) .* targetDirection)
end



# function heuristicDirection(walker::StepWalker)
#     targetDirection = normalize(walker.target.position .- walker.position)

#     bestStep = walker.position .+ (targetDirection .* WALKER_SPEED)
#     bestCost = costAt(walker.simulation.world, roundtogrid(bestStep)) +
#                norm(walker.target.position .- bestStep) * walker.simulation.settings.maxCost

#     for angleDiff ∈ -π/2:π/HEURISTIC_NUM_ANGLES:π/2

#         stepDirection = rotate(targetDirection, angleDiff)
#         step = walker.position .+ stepDirection
#         cost = costAt(walker.simulation.world, roundtogrid(step)) +
#                norm(walker.target.position .- step) * walker.simulation.settings.maxCost

#         if cost < bestCost
#             bestStep = step
#             bestCost = cost
#         end
#     end

#     return normalize(bestStep)
# end


"""
Determines the appropriate direction to walk towards, using the "lifeguard heuristic".
"""
function heuristicDirection(
        currentPosition :: Position,
        targetPosition :: Position,
        costAt :: Function,
        maxCost :: Float64,
        numAngles :: Int,
        walkerSpeed :: Float64,
    ) :: Direction
    
    targetDirection :: Direction = normalize(targetPosition .- currentPosition)

    bestStep = currentPosition .+ (targetDirection .* walkerSpeed)
    bestCost = costAt(bestStep) +
               norm(targetPosition .- bestStep) * maxCost

    for angleDiff ∈ -π/2:π/(numAngles - 1):π/2

        stepDirection = rotate(targetDirection, angleDiff)
        step = currentPosition .+ (stepDirection .* walkerSpeed)
        cost = costAt(step) +
               norm(targetPosition .- step) * maxCost

        if cost < bestCost
            bestStep = step
            bestCost = cost
        end
    end

    return normalize(bestStep .- currentPosition)
end

@testitem "heuristicDirection" begin
    using Paths, Test

    @test Paths.heuristicDirection((0.0, 0.0), (1.0, 0.0), x -> 1.0, 2.0, 30, 1.0) == (1.0, 0.0)
    @test Paths.heuristicDirection((1.0, 0.0), (0.0, 0.0), x -> 1.0, 2.0, 30, 1.0) == (-1.0, 0.0)
    @test Paths.heuristicDirection((0.0, 1.0), (0.0, 0.0), x -> 1.0, 2.0, 30, 1.0) == (0.0, -1.0)
    @test Paths.heuristicDirection((0.0, 0.0), (3.0, 4.0), x -> 1.0, 2.0, 30, 1.0) == (0.6, 0.8)

    function costAtMock(p)
        if collect(p) ≈ collect((1.0, 0.0))
            1.0
        else
            100000.0
        end
    end

    @test collect(Paths.heuristicDirection((0.0, 0.0), (1.0, 1.0), costAtMock, 2.0, 5, 1.0)) ≈ collect((1.0, 0.0))

end