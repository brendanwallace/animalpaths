package gridpaths

import (
	"math/rand"
	"time"
)

func init() {
	rand.Seed(time.Now().UnixNano())
}

type Position struct {
	x, y int
}

// Use to index into the 1D versions of the world.
type Index int

type Animal struct {
	pos    Position
	target Position
	path   []Position
	home   Position
}

type Patch struct {
	cost float64
}

// World represents the game state.
type World struct {
	// state:
	patches []*Patch
	animals []*Animal
	// settings:
	WIDTH                int
	HEIGHT               int
	ANIMALS              int
	FLATTEN_COEFFICIENT  float64
	MAX_COST             float64
	MIN_COST             float64
	RECOVERY_COEFFICIENT float64
	NEIGHBOR_FLATTEN     float64
	ALL_RANDOM           bool
	TORUS                bool
}

// NewWorld creates a new world.
func (w *World) Initialize() {
	w.patches = make([]*Patch, w.WIDTH*w.HEIGHT)
	w.animals = make([]*Animal, w.ANIMALS)
	for p := range w.patches {
		w.patches[p] = &Patch{w.MAX_COST}
	}
	for a := range w.animals {

		start := Position{x: rand.Int() % w.WIDTH, y: rand.Int() % w.HEIGHT}
		w.animals[a] = &Animal{
			pos:    start,
			path:   make([]Position, 0),
			target: start,
		}
	}
}

// Assigns a new target for a.
func (w *World) NewTarget(a *Animal) {
	if w.ALL_RANDOM {
		// Assume we're at our target.
		a.target = Position{x: rand.Int() % w.WIDTH, y: rand.Int() % w.HEIGHT}
	} else {
		a.target = Position{x: 0, y: rand.Int() % w.HEIGHT}
		if a.pos.x == 0 {
			a.target.x = w.WIDTH - 1
		}
	}
}

// If we're not home, go home.
// Assumes the path is already empty.
func (w *World) ChartAPath(a *Animal) {
	// If we're at our target, we need a new target:
	if a.pos == a.target {
		w.NewTarget(a)
	}

	a.path = w.FindPath(a.pos, a.target)
}

func (w *World) Recover(p *Patch) {
	// Logistic recovery
	p.cost = p.cost + w.RECOVERY_COEFFICIENT*(p.cost/w.MAX_COST)*(1-p.cost/w.MAX_COST)
}

func (w *World) Flatten(p *Patch, modifier float64) {
	p.cost = p.cost * (1.0 - w.FLATTEN_COEFFICIENT*modifier)
}

func (w *World) index(pos Position) Index {
	return Index(pos.x + pos.y*w.WIDTH)
}

func (w *World) patch(pos Position) *Patch {
	return w.patches[w.index(pos)]
}

func (w *World) Cost(pos Position) float64 {
	return w.patch(pos).cost + w.MIN_COST
}

func (w *World) FlattenPath(pos Position) {
	w.Flatten(w.patch(pos), 1.0)
	for _, n := range w.neighbors(pos) {
		w.Flatten(w.patch(n), w.NEIGHBOR_FLATTEN)
	}
}

func (a *Animal) Move(w *World) {
	for len(a.path) == 0 {
		w.ChartAPath(a)
	}

	// Pop the first position off the queue and go there.
	a.pos, a.path = a.path[0], a.path[1:]

	w.FlattenPath(a.pos)
}

func (w *World) Update() {
	for _, a := range w.animals {
		a.Move(w)
	}

	for _, p := range w.patches {
		w.Recover(p)
	}
}

// Draw paints current game state.
func (w *World) Draw(pix []byte) {

	for p, patch := range w.patches {
		shading := byte((1.0 - (patch.cost)/(w.MAX_COST)) * 255)

		pix[p*4] = shading
		pix[p*4+1] = shading
		pix[p*4+2] = shading
		pix[p*4+3] = 0x20
	}

	for _, animal := range w.animals {

		animalPos := w.index(animal.pos)

		// setting each of the primary colors to full?!
		pix[animalPos*4] = 20
		pix[animalPos*4+1] = 150
		pix[animalPos*4+2] = 20
		pix[animalPos*4+3] = 0xff
	}

}
