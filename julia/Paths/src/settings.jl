import Base.@kwdef

# Controls where walkers go.
@enum Scenario begin
    RANDOM_FIXED = 1
    RANDOM_DYNAMIC = 2
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
    DIRECT_SEARCH = 2
    GRADIENT_WALKER = 3
    # This one only works with HEX_WORLD grid type.
    GRID_WALK = 4
end

"""
Controls whether the world is a square grid or a hexagon grid.
"""
@enum GridType begin
    SQUARE_WORLD = 1
    HEX_WORLD = 2
end


# General settings object.
@kwdef mutable struct Settings
    X::Integer = 100
    Y::Integer = 100
    randomSeed::Integer = 1
    numWalkers::Integer = 10
    numLocations::Integer = 10
    scenario::Scenario = RANDOM_FIXED

    # WALKER SETTINGS
    maxCost::Float64 = 2.0
    searchStrategy::SearchStrategy = KANAI_SUZUKI
    # analog to maxCost, used for GRADIENT_WALKER search strategy only
    comfortWeight::Float64 = 0.5

    # WORLD SETTINGS
    gridType::GridType = SQUARE_WORLD
    patchImprovement::Float64 = 0.02
    patchRecovery::Float64 = 0.0002
    diffusionRadius::Integer = 3
    diffusionGaussianVariance::Float64 = 1.0
    improvementLogic::PatchLogic = LINEAR
    recoveryLogic::PatchLogic = LINEAR
end
