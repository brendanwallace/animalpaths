
const TEXT_SIZE = 10

function describe(settings::Settings)
    return "i:$(settings.patchImprovement), r:$(settings.patchRecovery), cost:$(settings.maxCost)"
end

function viz(sim)
    X = sim.settings.X
    Y = sim.settings.Y
    discounts = sim.settings.maxCost .- costs(sim.world)
    patches = heatmap(1.5:(X+0.5), 1.5:(Y+0.5), transpose(discounts), axis=([], false), clims=(0, sim.settings.maxCost - 1), legend=nothing, aspect_ratio=:equal)
    walkers = scatter!([(w.position[1], w.position[2]) for w in sim.walkers], label="", axis=([], false), color="#1f77b4")
    locations = scatter!([(l.position[1], l.position[2]) for l in sim.locations], label="", axis=([], false), color="#ff7f0e")

    annotate!(sim.settings.X, 1, text(sim.steps, :white, :right, :bottom, TEXT_SIZE))
    annotate!(1, 1, text(describe(sim.settings), :white, :left, :bottom, TEXT_SIZE))
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
