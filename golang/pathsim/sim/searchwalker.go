package sim

import "math/rand"

type DirectWalker struct {
	Target     *Location
	simulation *Simulation
}

func (w *DirectWalker) update() {
	if w.Target == nil {
		w.Target = w.simulation.Locations[rand.Intn(len(w.simulation.Locations))]
	}
	//
}

type SearchWalker struct {
	Target     *Location
	simulation *Simulation
}

func (w *SearchWalker) update() {
	if w.Target == nil {
		w.Target = w.simulation.Locations[rand.Intn(len(w.simulation.Locations))]
	}
	//
}
