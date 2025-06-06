using Plots
using Random
using Paths
using Dates

const UPF = 50
const F = 1000
const FPS = 30
const showtext = true

const patchRecovery = 0.0005
const improvementRatio = 150
const maxCost = 2


function animate()

    if length(ARGS) < 1
        throw("supply a name for this series by running `julia $(PROGRAM_FILE) [series name]`")
    else
        animName = ARGS[1]
    end

    patchImprovement = patchRecovery * improvementRatio

    settings = Paths.Settings(
        maxCost=maxCost,
        scenario=Paths.RANDOM_FIXED,
        # searchStrategy=searchStrategy,
        patchImprovement=pI,
        patchRecovery=pR,
        improvementLogic=patchLogic,
        recoveryLogic=patchLogic,
        numSteinerPoints=2,
        randomSeedWalkers=replica,
        randomSeedLocations=locationSeed,
        boundaryConditions=boundaryCondition,
        numLocations=nLocations,
        # comfortWeight=comfort,
    )


    showwalkers = UPF <= 8
    showlocations = settings.scenario !== Paths.RANDOM_DYNAMIC

    animfile = "data/animations/$(animName).gif"

    @info "saving file to $(animfile)"
    sim = Paths.MakeSimulation(settings)

    anim = @animate for f ∈ 1:F
        print("\r$(f)/$(F)")
        for _ ∈ 1:UPF
            Paths.update!(sim)
        end
        Paths.viz(sim, showtext=showtext, showwalkers=showwalkers, showlocations=showlocations, markersize=7)
    end
    gif(anim, animfile, fps=FPS)
end



animate()