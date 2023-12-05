package grid

import (
	"bw/animal_paths/world"
	"math/rand"
)

type Animal struct {
	pos    world.GridPosition
	target world.GridPosition
	path   []world.GridPosition
	home   world.GridPosition
}

func InitializeAnimals() []world.Animal {
	animals := make([]world.Animal, world.ANIMALS)
	for a := range animals {

		start := world.GridPosition{X: rand.Int() % world.WIDTH, Y: rand.Int() % world.HEIGHT}
		animals[a] = &Animal{
			pos:    start,
			path:   make([]world.GridPosition, 0),
			target: start,
		}
	}
	return animals
}

func (a *Animal) GridPosition() world.GridPosition {
	return a.pos
}

// NewTarget assigns a new target for a.
func (a *Animal) NewTarget(w *world.World) {
	if world.ALL_RANDOM {
		// Assume we're at our target.
		a.target = world.GridPosition{X: rand.Int() % world.WIDTH, Y: rand.Int() % world.HEIGHT}
	} else {
		//a.target = world.GridPosition{X: 0, Y: rand.Int() % w.HEIGHT}
		//if a.pos.X == 0 {
		//	a.target.X = w.WIDTH - 1
		//}
		a.target = w.PointsOfInterest[rand.Intn(len(w.PointsOfInterest))].Position
	}
}

// ChartAPath directs the animals new path according to:
// If we're not home, go home.
// Assumes the path is already empty.
func (a *Animal) ChartAPath(w *world.World) {
	// If we're at our target, we need a new target:
	if a.pos == a.target {
		a.NewTarget(w)
	}

	a.path = FindPath(a.pos, a.target, w)
}

func (a *Animal) Move(w *world.World) {
	for len(a.path) == 0 {
		a.ChartAPath(w)
	}

	// Pop the first world.position off the queue and go there.
	a.pos, a.path = a.path[0], a.path[1:]

	w.FlattenPath(a.pos)
}
