using .Paths

# function main()
#     Random.seed!(2)
# 	sim::Simulation = Simulation(DEFAULT_SCENARIO)
#     for i in 1:100000
#         update!(sim)
#     end
# end

function viz(sim)
    patches = heatmap(transpose(sim.world.patches), axis=([], false), clims=(0, 1), legend=nothing)
    walkers = scatter!([(w.pos[1], w.pos[2]) for w in sim.walkers], label="", axis=([], false), color="#1f77b4")
    locations = scatter!([(l.pos[1], l.pos[2]) for l in sim.locations], label="", axis=([], false), color="#ff7f0e")
end

const T = 100

function main()
    Random.seed!(2)
	sim::Simulation = Simulation(DEFAULT_SCENARIO)
    @gif for i in 1:100
    	for t in 1:T
        	update!(sim)
        end
        viz(sim)
    end
end


# main()