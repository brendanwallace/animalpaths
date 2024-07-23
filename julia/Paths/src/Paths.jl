module Paths

using Dates: now
using Plots
using Random
using Test, TestItems

export update!, Simulation, RANDOM_FIXED, RANDOM_DYNAMIC
export Node, Edge, shortestPath

include("common.jl")
include("search.jl")
include("simulation.jl")
include("world.jl")
include("scenario.jl")
include("walker.jl")

function viz(sim)
    X = sim.world.X
    Y = sim.world.Y
    patches = heatmap(1.5:(X + 0.5), 1.5:(Y+0.5), transpose(sim.world.patches), axis=([], false), clims=(0, 1), legend=nothing, aspect_ratio=:equal)
    walkers = scatter!([(w.position[1], w.position[2]) for w in sim.walkers], label="", axis=([], false), color="#1f77b4")
    locations = scatter!([(l.position[1], l.position[2]) for l in sim.locations], label="", axis=([], false), color="#ff7f0e")

    # TODO -- add this text
    # sim_ax.text(0, scenario.HEIGHT, animation_describe(upf), color='white', verticalalignment='top')
    # sim_ax.text(0, 0, s.world.describe(), color='white', fontsize=FONT_SIZE)
    # frame_text = sim_ax.text(scenario.WIDTH, 0, "0", color="white", fontsize=FONT_SIZE, horizontalalignment='right')


end

# const DEFAULT_L = 100::Int
# const NUM_LOCATIONS = 10
# const NUM_WALKERS = 10
# const PATCH_IMPROVEMENT = 0.05
# const PATCH_RECOVERY = 0.0003
const MAX_COST = 2.0
# const DEFAULT_FPS = 20
# const DEFAULT_UPF = 2


function main(
    ;T=1000,
    upf=2,
    X=100,
    Y=100,
    numWalkers = 10,
    numLocations = 10,
    pI = 0.05,
    pR = 0.0005,
    scenario = RANDOM_FIXED,
    # TODO -- maxCost= 2.0,
    fps=30,
    save=true,
)

    filetext = "animations/$(scenario.description)|$(X)x$(Y)|pI=$(pI)|pR=$(pR)|UPF=$(upf)|T=$(T).gif"


    Random.seed!(2)

    @info "Creating simulation. $(X)x$(Y), $(numWalkers) walkers, $(numLocations) locations, UPF:$(upf), Frames:$(T)";
    @info "Creating simulation. patchImprovement: $(pI), patchRecovery: $(pR), maxCost: $(MAX_COST)"
    if save
        @info "Will save to $(filetext)"
    end


    sim::Simulation = MakeSimulation(
        X=X, Y=Y, numWalkers=numWalkers, numLocations=numLocations,
        patchImprovement=pI, patchRecovery=pR,
        scenario=scenario, maxCost=MAX_COST)

    anim = @animate for t in 1:T
        print("\r$(t)/$(T)")
        for u in 1:upf
            update!(sim)
        end
        viz(sim)
    end
    if save
        gif(anim, filetext, fps = fps)
    end
end

function profilemain(
    ;T=1000,
    upf=2,
    X=100,
    Y=100,
    numWalkers = 10,
    numLocations = 10,
    pI = 0.05,
    pR = 0.0005,
    scenario = RANDOM_FIXED,
    # TODO -- maxCost= 2.0,
    fps=30,
)

    @info "Creating simulation. $(X)x$(Y), $(numWalkers) walkers, $(numLocations) locations, UPF:$(upf), Frames:$(T)";
    @info "Creating simulation. patchImprovement: $(pI), patchRecovery: $(pR), maxCost: $(MAX_COST)"

    sim::Simulation = MakeSimulation(
        X=X, Y=Y, numWalkers=numWalkers, numLocations=numLocations,
        patchImprovement=pI, patchRecovery=pR,
        scenario=scenario, maxCost=MAX_COST)

    for t in 1:T
        update!(sim)
    end
end


end # module Paths
