using Plots
using Random
using Paths
using Dates

const UPF = 1
const F = 1000
const FPS = 30
const showtext = false

function animate()

    settings = Paths.Settings(
        maxCost=2.0,
        comfortWeight=0.3,
        scenario=Paths.RANDOM_DYNAMIC,
        searchStrategy=Paths.KANAI_SUZUKI,
        patchImprovement=0.05,
        patchRecovery=0.0005,
        recoveryLogic=Paths.LINEAR,
        improvementLogic=Paths.LINEAR,
        X=100,
        Y=100,
        randomSeed=1,
        # numLocations=15,
    )

    animfile = "data/animations/$(now()).gif"

    @info "saving file to $(animfile)"
    sim = Paths.MakeSimulation(settings)

    anim = @animate for f ∈ 1:F
        print("\r$(f)/$(F)")
        for _ ∈ 1:UPF
            Paths.update!(sim)
        end
        Paths.viz(sim, showtext=showtext)
    end
    gif(anim, animfile, fps=FPS)
end


animate()