using Plots
using Random
using Paths
using Dates

const UPF = 2
const F = 100
const FPS = 30
const showtext = true

function animate()

    settings = Paths.Settings(
        maxCost=2.0,
        comfortWeight=0.3,
        scenario=Paths.RANDOM_FIXED,
        searchStrategy=Paths.KANAI_SUZUKI,
        patchImprovement=0.75,
        patchRecovery=0.001,
        recoveryLogic=Paths.LOGISTIC,
        improvementLogic=Paths.LOGISTIC,
        X=100,
        Y=100,
        randomSeed=1,
        numLocations=15,
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