
const SHORTCUT_FIRST_SEARCH = true

"""
This walker uses a search algorithm to plot a path, and then takes steps along
that path to its target.
"""
mutable struct SearchWalker <: Walker
    simulation::Simulation
    target::Union{Location,Nothing}
    position::Tuple{Float64,Float64}
    path::Array{Position}
    SearchWalker(simulation, target, position) = new(simulation, target, position, [])
end


function newpath!(walker::SearchWalker)

    strategy = walker.simulation.settings.searchStrategy

    if strategy == KANAI_SUZUKI

        if SHORTCUT_FIRST_SEARCH && walker.simulation.settings.boundaryConditions == SOLID
            if walker.simulation.steps == 0
                walker.path = [walker.target.position]
                @debug "setting walker path to $(walker.path) (coming from $(walker.position))"
                return
            end
        end

        walker.path, _cost = shortestPathKanaiSuzuki(
            walker.position,
            walker.target.position,
            costs(walker.simulation.world),
            bc=walker.simulation.settings.boundaryConditions,
            numSteinerPoints=walker.simulation.settings.numSteinerPoints,
        )
        @info "$(walker.simulation.steps) walker heading from $(walker.position) to $(walker.target.position)"
        # @info "using path $(walker.path)"
    elseif strategy ∈ [GRID_WALK_4, GRID_WALK_8, GRID_WALK_HEX, GRID_WALK_HEX_PLUS]
        gridPath::Array{GridPosition}, _ = gridSearch(
            walker.position, walker.target.position,
            walker.simulation.world, walker.simulation.settings)

        walker.path = [Float64.(p) for p in gridPath]
    else
        throw("search strategy $(strategy) not handled")
    end
end




function update!(walker::SearchWalker)
    if walker.target isa Nothing
        newtarget!(walker)
        newpath!(walker)
    end

    travelBudget = WALKER_SPEED
    while travelBudget > 0
        if length(walker.path) == 0
            # @info "walker ran out of path at $(walker.position) without arriving at $(walker.target.position)."
            prevTarget = walker.target

            newtarget!(walker)
            newpath!(walker)
            # TODO – could require that we actually hit a distinct new target, and then we could keep walking.
            # This runs a risk of live-lock when there's only one legal target.
            break
        end

        nextPosition = walker.path[1]
        stepLength = norm(nextPosition .- walker.position)
        if walker.simulation.settings.boundaryConditions == PERIODIC
            stepLength = periodicNorm(nextPosition, walker.position,
                walker.simulation.settings.X,
                walker.simulation.settings.Y)
        end

        # @info "nextPosition: $(nextPosition), stepLength: $(stepLength), travelBudget: $(travelBudget)"
        
        # If this step would take us past our remaining travel budget, we want
        # to use up the rest of the travel budget but not pop the next position
        # from the path.
        # If boundary conditions are PERIODIC, we just take the full-length step.
        # 
        # TODO - we could try to also take partial steps in the PERIODIC condition, it just involves
        # deciding between four possible directions towards the next step and taking the shortest one.
        # Could implemement something like periodicTowards(from, to) that gives this direction.
        if stepLength > travelBudget && walker.simulation.settings.boundaryConditions == SOLID
            nextPosition = walker.position .+ 
                (travelBudget .* (nextPosition .- walker.position) ./ stepLength)
            stepLength = travelBudget
            travelBudget = 0.0
        else
            popfirst!(walker.path)
            travelBudget -= stepLength
        end

        walker.position = nextPosition
        @info "$(walker.position), $(stepLength)"
        facesToImprove = faces((nextPosition .+ walker.position) ./ 2)
        for face in facesToImprove
            improvePatch!(
                walker.simulation.world,
                face,
                stepLength / length(facesToImprove),
            )
        end
    end
    @info "$(walker.simulation.steps) $(walker.position)"
end



