package main

import (
	"github.com/brendanwallace/pathsim/sim"
)

func main() {
	settings := sim.Settings{
		X:                4,
		Y:                4,
		NumWalkers:       2,
		NumLocations:     2,
		PatchImprovement: 0.1,
		PatchRecovery:    0.01,
		MaxCost:          2,
	}
	s := sim.NewSimulation(settings)

	s.Describe()
	s.Update()
	// fmt.Println("hello, world.")
	s.Describe()
}
