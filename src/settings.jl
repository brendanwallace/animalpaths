import Base.@kwdef

# Controls where walkers go.
@enum Scenario begin
    RANDOM_FIXED = 1
    RANDOM_DYNAMIC = 2
    TRIANGLE = 3
end


# Controls how the patches recover.
@enum PatchLogic begin
    # TODO – add a description of these.
    LINEAR = 1
    LOGISTIC = 2
    SATURATING = 3
end


"""
Controls how the walker searches and paths.

TODO – it would be cool if all these worked for both SQUARE_WORLD and
HEX_WORLD neighborhoods.
"""
@enum SearchStrategy begin
    # Currently these only works with SQUARE_WORLD neighborhood and allow for
    # continuous movement.
    KANAI_SUZUKI = 1
    DIRECT_WALK = 2
    GRADIENT_WALK = 3
    GRID_WALK_4 = 4
    GRID_WALK_8 = 5
    GRID_WALK_HEX = 6
    GRID_WALK_HEX_PLUS = 7
    HEURISTIC_WALK = 8
end

# These all sets of strategies that share a lot of logic.
const SEARCH_WALKS = [KANAI_SUZUKI, GRID_WALK_4, GRID_WALK_8, GRID_WALK_HEX, GRID_WALK_HEX_PLUS]
const SQUARE_WORLD_STRATEGIES = [KANAI_SUZUKI, DIRECT_WALK, GRADIENT_WALK, GRID_WALK_4, GRID_WALK_8, HEURISTIC_WALK]
const HEX_WORLD_STRATEGIES = [GRID_WALK_HEX, GRID_WALK_HEX_PLUS]
const STEP_WALKS = [DIRECT_WALK, GRADIENT_WALK, HEURISTIC_WALK]

# """
# Controls whether the world is a square grid or a hexagon grid.
# """
# @enum GridType begin
#     SQUARE_WORLD = 1
#     HEX_WORLD = 2
# end

@enum BoundaryConditions begin
    SOLID = 1
    PERIODIC = 2
end


# General settings object.
@kwdef mutable struct Settings
    X::Integer = 100
    Y::Integer = 100
    randomSeedWalkers::Integer = 1
    randomSeedLocations::Integer = 1
    numWalkers::Integer = 10
    numLocations::Integer = 10
    scenario::Scenario = RANDOM_FIXED

    # WALKER SETTINGS
    maxCost::Float64 = 2.0
    searchStrategy::SearchStrategy = KANAI_SUZUKI

    # Only applies to the KANAI_SUZUKI algorithm
    numSteinerPoints::Int64 = 3
    # analog to maxCost, used for GRADIENT_WALK search strategy only
    comfortWeight::Float64 = 0.5

    # WORLD SETTINGS
    # gridType::GridType = SQUARE_WORLD
    patchImprovement::Float64 = 0.2
    patchRecovery::Float64 = 0.002
    diffusionRadius::Integer = 3
    diffusionGaussianVariance::Float64 = 1.0
    improvementLogic::PatchLogic = LOGISTIC
    recoveryLogic::PatchLogic = LOGISTIC
    boundaryConditions::BoundaryConditions = SOLID
end
