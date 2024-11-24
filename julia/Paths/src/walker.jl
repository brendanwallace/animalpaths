const ARRIVAL_DISTANCE = 1.0
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


mutable struct GradientWalker <: Walker
    simulation::Simulation
    target::Union{Location,Nothing}
    position::Position
end

function gradientAt(position::Position, world::World)::Position
    x, y = Int.(floor.(position))
    gX = 0.0
    gY = 0.0
    sobelX = [
        [-1, 0, 1],
        [-2, 0, 2],
        [-1, 0, 1]]
    sobelY = [
        [-1, -2, -1],
        [0, 0, 0],
        [1, 2, 1]]
    for dx in [-1, 0, 1]
        for dy in [-1, 0, 1]
            gX += comfortAt(world, x + dx, y + dy) * sobelX[dy+2][dx+2]
            gY += comfortAt(world, x + dx, y + dy) * sobelY[dy+2][dx+2]
        end
    end
    # println("gradient", (gX, gY))
    return (gX, gY)
end

function arrived(walker::Walker)::Bool
    return norm(walker.position .- walker.target.position) <= ARRIVAL_DISTANCE
end


"""
Just needs to add a target (if it doesn't have one), and take a single step.
"""
function update!(walker::GradientWalker)
    if walker.target isa Nothing || arrived(walker)
        newtarget!(walker)
    end

    # choose direction
    targetDirection = normalize(walker.target.position .- walker.position)

    comfortDirection = normalize(gradientAt(walker.position, walker.simulation.world))
    # (detect gradient)

    cw = walker.simulation.settings.comfortWeight
    step = normalize(cw .* comfortDirection .+ (1.0 - cw) .* targetDirection) .* WALKER_SPEED

    # take a step
    walker.position = walker.position .+ step
    improvePatch!(walker.simulation.world, Int.(floor.(walker.position)), 1.0)
    # println("new walker position", walker.position)
end



"""
This walker uses the Kanai Suzuki shortest-path algorithm.
"""
mutable struct SearchWalker <: Walker
    simulation::Simulation
    target::Union{Location,Nothing}
    position::Tuple{Float64,Float64}
    path::Array{Position}
    SearchWalker(simulation, target, position) = new(simulation, target, position, [])
end


function newpath!(walker::SearchWalker)
    walker.path, _cost = shortestPathKanaiSuzuki(
        walker.position,
        walker.target.position,
        costs(walker.simulation.world),
    )
end


function update!(walker::SearchWalker)
    if walker.target isa Nothing
        newtarget!(walker)
        newpath!(walker)
    end

    traveled = 0.0
    while traveled < WALKER_SPEED
        if length(walker.path) == 0
            @debug "walker ran out of path at $(walker.position) without arriving at $(walker.target.position)."
            prevTarget = walker.target

            newtarget!(walker)
            newpath!(walker)
            # TODO – could require that we actually hit a new target, and then we could keep walking.
            break
        end
        nextPosition = walker.path[1]
        # This should be in the middle of the correct square.
        # TODO -- this should put more weight into the face which has lower cost if
        # we're walking right along an edge.
        improvePosition = (nextPosition .+ walker.position) ./ 2
        nextEdgeLength = norm(nextPosition .- walker.position)
        facesToImprove = faces(improvePosition)
        if (traveled + nextEdgeLength) < WALKER_SPEED
            walker.position = nextPosition
            for face in facesToImprove
                improvePatch!(
                    walker.simulation.world,
                    face,
                    nextEdgeLength / length(facesToImprove),
                )
            end
            traveled += nextEdgeLength
            popfirst!(walker.path)
        else
            distanceToTravel = WALKER_SPEED - traveled
            walker.position =
                walker.position .+
                (distanceToTravel .* (nextPosition .- walker.position))
            for face in facesToImprove
                improvePatch!(
                    walker.simulation.world,
                    face,
                    distanceToTravel / length(facesToImprove),
                )
            end
            traveled = WALKER_SPEED
        end
    end
end


mutable struct DirectWalker <: Walker
    simulation::Simulation
    target::Union{Location,Nothing}
    position::Tuple{Float64,Float64}
end


function update!(walker::DirectWalker)
    if walker.target isa Nothing
        newtarget!(walker)
    end
    arrived = norm(walker.position .- walker.target.position) <= ARRIVAL_DISTANCE
    if arrived
        newtarget!(walker)
    else
        direction = normalize(walker.target.position .- walker.position)
        walker.position = walker.position .+ (direction .* WALKER_SPEED)
        improvePatch!(walker.simulation.world, roundtogrid(walker.position), 1.0)
    end
end

"""
GridWalker plans a discrete path through the grid, considering only
integer-defined positions.

TODO -- refactor this into shared code with SearchWalker.
"""
mutable struct GridWalker <: Walker
    simulation::Simulation
    target::Union{Location,Nothing}
    position::Position
    path::Array{Position}
    GridWalker(simulation, target, position) = new(simulation, target, position, [])
end


"""
Needs to use A-star search.
"""
function newpath!(walker::GridWalker)

    gridPath::Array{GridPosition}, _ = gridSearch(
        walker.position, walker.target.position,
        walker.simulation.world, walker.simulation.settings.searchStrategy)

    walker.path = [Float64.(p) for p in gridPath]
end


"""
TODO – why does this not work if the paths are out-of-bounds?
"""
function update!(walker::GridWalker)
    if walker.target isa Nothing || length(walker.path) <= 0
        newtarget!(walker)
        newpath!(walker)
    end
    # This can happen if there's only 1 location, or we somehow select the
    # position we started at.
    if length(walker.path) <= 0
        @debug "walker $(walker) ran out of path without taking a step"
        return
    end
    # Take a step. by definition this is of length 1.
    # TODO - reintroduce non-integer steps to allow proper diogonal pathing.
    walker.position = popfirst!(walker.path)
    improvePatch!(walker.simulation.world, roundtogrid(walker.position), 1.0)
end


