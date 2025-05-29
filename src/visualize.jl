
const TEXT_SIZE = 10
const MARKER_SIZE = 5

function describePatches(settings::Settings)
    return "i:$(settings.patchImprovement), r:$(settings.patchRecovery), cost:$(settings.maxCost)"
end

function describeScenario(settings::Settings)
    return "$(settings.searchStrategy)"
end

function describeMeasures(sim)
    return "$(Integer(round(totalImprovement(sim.world.patches))))"
end

function viz(sim; showtext=true, showwalkers=true, showlocations=true, markersize=MARKER_SIZE)
    X = sim.settings.X
    Y = sim.settings.Y
    discounts = sim.settings.maxCost .- costs(sim.world)
    patches = heatmap(1.5:(X+0.5), 1.5:(Y+0.5), transpose(discounts), axis=([], false), clims=(0, sim.settings.maxCost - 1), legend=nothing, aspect_ratio=:equal)
    if showwalkers
        walkers = scatter!(
            [(w.position[1], w.position[2]) for w in sim.walkers],
            label="", axis=([], false), color="#1f77b4", markersize=markersize,
        )
    end
    if showlocations
        locations = scatter!(
            [(l.position[1], l.position[2]) for l in sim.locations],
            label="", axis=([], false), color="#ff7f0e", markersize=markersize,
        )
    end
    if showtext
        annotate!(sim.settings.X, 1, text(sim.steps, :white, :right, :bottom, TEXT_SIZE))
        annotate!(sim.settings.X, 1 + TEXT_SIZE / 2, text(describeMeasures(sim), :white, :right, :bottom, TEXT_SIZE))
        annotate!(1, 1, text(describePatches(sim.settings), :white, :left, :bottom, TEXT_SIZE))
        annotate!(1, 1 + TEXT_SIZE / 2, text("$(sim.settings.recoveryLogic)", :white, :left, :bottom, TEXT_SIZE))
        annotate!(1, 1 + TEXT_SIZE, text(describeScenario(sim.settings), :white, :left, :bottom, TEXT_SIZE))
    end
    return patches
end

function animate(upf=5, frames=100, settings=Paths.Settings())
    sim = Paths.MakeSimulation(settings)
    @gif for t in 1:frames
        for u in 1:upf
            Paths.update!(sim)
        end
        # p = [(sim.world.patches...)...]
        # histogram(p[p.>0.2])
        Paths.viz(sim)
    end
end
