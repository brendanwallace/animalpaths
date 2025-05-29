/*
This file contains the top-level interfaces and the outer-most Simulation struct.

See main.go for actually running the simulation.
*/
package sim

import (
	"encoding/json"
	"fmt"
)

type Walker interface {
	update()
}

type Position struct {
	X float64
	Y float64
}

// type Scenario interface {
// }

type Location struct {
	Pos Position
}

type Settings struct {
	X                int64
	Y                int64
	NumWalkers       int64
	NumLocations     int64
	PatchImprovement float64
	PatchRecovery    float64
	MaxCost          float64
}

type Simulation struct {
	World *World
	// scenario  Scenario
	Walkers   []Walker
	Locations []*Location
}

func (s *Simulation) Update() {
	for _, w := range s.Walkers {
		w.update()
	}
	s.World.update()
}

func makeWalkers(settings Settings, sim *Simulation) []Walker {
	walkers := make([]Walker, settings.NumWalkers)
	for i, _ := range walkers {
		walkers[i] = &SearchWalker{nil, sim}
	}
	return walkers
}

func makeLocations(settings Settings) []*Location {
	locations := make([]*Location, settings.NumLocations)
	// if random locations
	for i, _ := range locations {
		locations[i] = &Location{randomPosition(settings)}
	}
	return locations
}

func NewSimulation(settings Settings) *Simulation {

	sim := &Simulation{}

	sim.World = NewWorld(settings)
	sim.Walkers = makeWalkers(settings, sim)
	sim.Locations = makeLocations(settings)
	// sim.scenario = scenario;

	return sim
}

func (sim *Simulation) Describe() {
	jsim, _ := json.MarshalIndent(sim, "", " ")
	fmt.Println(string(jsim))
	// fmt.Println(sim.World.patches)
	// fmt.Println(sim.Walkers)
	// fmt.Println(sim.Locations)
}
