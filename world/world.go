package world

import (
	"math"
	"math/rand"
	"time"
)

func init() {
	rand.Seed(time.Now().UnixNano())
}

// GridPosition are positions of things that are strictly
// on the grid, e.g. patch tiles (Patches) and grid animals.
type GridPosition struct {
	X, Y int
}

// Index is used to index into the 1D versions of the world.
type Index int

type Animal interface {
	GridPosition() GridPosition
	Move(w *World)
}

type Patch struct {
	cost float64
}

type PointOfInterest struct {
	Position GridPosition
}

// World represents the game state.
type World struct {
	// state:
	patches          []*Patch
	animals          []Animal
	PointsOfInterest []PointOfInterest
}

// Initialize creates a new world.
func (w *World) Initialize(animals []Animal) {
	w.animals = animals

	w.patches = make([]*Patch, WIDTH*HEIGHT)
	for p := range w.patches {
		w.patches[p] = &Patch{1.0}
	}

	if POINTS_OF_INTEREST_MODE == POI_RANDOM {
		w.PointsOfInterest = make([]PointOfInterest, POINTS_OF_INTEREST)
		for p := range w.PointsOfInterest {
			x := WIDTH - 1
			y := rand.Intn(HEIGHT)
			w.PointsOfInterest[p] = PointOfInterest{GridPosition{x, y}}
		}
	} else if POINTS_OF_INTEREST_MODE == POI_SET {
		w.PointsOfInterest = []PointOfInterest{
			{GridPosition{10, 10}},
		}
	}

}

func (w *World) Recover(p *Patch) {
	// Logistic recovery
	p.cost = p.cost + RECOVERY_COEFFICIENT*(p.cost)*(1-p.cost)
}

func (w *World) Flatten(p *Patch, modifier float64) {
	p.cost = p.cost * (1.0 - FLATTEN_COEFFICIENT*modifier)
}

func (w *World) index(pos GridPosition) Index {
	return Index(pos.X + pos.Y*WIDTH)
}

func (w *World) patch(pos GridPosition) *Patch {
	return w.patches[w.index(pos)]
}

func (w *World) Cost(pos GridPosition) float64 {
	if pos.X >= WIDTH || pos.X < 0 || pos.Y >= HEIGHT || pos.Y < 0 {
		return math.Inf(1)
	}
	c := w.patch(pos).cost

	return c*MAX_COST + (1.0-c)*MIN_COST
}

func (w *World) Comfort(pos GridPosition) float64 {
	if pos.X >= WIDTH || pos.X < 0 || pos.Y >= HEIGHT || pos.Y < 0 {
		return 0.0
	}
	return 1.0 - w.patch(pos).cost
}

func (w *World) FlattenPath(pos GridPosition) {
	w.Flatten(w.patch(pos), 1.0)
	for _, n := range w.Neighbors(pos) {
		w.Flatten(w.patch(n), NEIGHBOR_FLATTEN)
	}
}

func (w *World) Update() {
	for _, a := range w.animals {
		a.Move(w)
	}

	for _, p := range w.patches {
		w.Recover(p)
	}
}

func (w *World) Neighbors(p GridPosition) []GridPosition {
	var neighbors []GridPosition
	for dx := -FLATTEN_RADIUS; dx <= FLATTEN_RADIUS; dx = dx + 1 {
		for dy := -FLATTEN_RADIUS; dy <= FLATTEN_RADIUS; dy = dy + 1 {
			neighbor := GridPosition{p.X + dx, p.Y + dy}
			if neighbor.X >= 0 && neighbor.X < WIDTH && neighbor.Y >= 0 && neighbor.Y < HEIGHT {
				if !(neighbor.X == p.X && neighbor.Y == p.Y) {
					neighbors = append(neighbors, neighbor)
				}
			}
		}
	}
	return neighbors
}

func (w *World) NeighborsOld(p GridPosition) []GridPosition {
	ns := make([]GridPosition, 0)

	if p.X+1 < WIDTH || TORUS {
		ns = append(ns, GridPosition{(p.X + 1) % WIDTH, p.Y})
	}
	if p.X-1 >= 0 || TORUS {
		ns = append(ns, GridPosition{(WIDTH + p.X - 1) % WIDTH, p.Y})
	}
	if p.Y+1 < HEIGHT || TORUS {
		ns = append(ns, GridPosition{p.X, (p.Y + 1) % HEIGHT})
	}
	if p.Y-1 >= 0 || TORUS {
		ns = append(ns, GridPosition{p.X, (HEIGHT + p.Y - 1) % HEIGHT})
	}
	return ns
}

// Draw paints current game state.
func (w *World) Draw(pix []byte) {

	for p, patch := range w.patches {
		//R, G, B := 12.0, 89.0, 35.0
		//r, g, b := 206.0, 176.0, 146.0
		R, G, B := 0.0, 0.0, 0.0
		r, g, b := 255.0, 255.0, 255.0

		//shading := byte((1.0 - (patch.cost)) * 255)

		pix[p*4] = byte(R*(patch.cost) + r*(1-patch.cost))
		pix[p*4+1] = byte(G*(patch.cost) + g*(1-patch.cost))
		pix[p*4+2] = byte(B*(patch.cost) + b*(1-patch.cost))
		pix[p*4+3] = 0x20
	}

	for _, animal := range w.animals {

		animalPos := w.index(animal.GridPosition())

		// setting each of the primary colors to full?!
		pix[animalPos*4] = 20
		pix[animalPos*4+1] = 150
		pix[animalPos*4+2] = 20
		pix[animalPos*4+3] = 0xff
	}

	for _, poi := range w.PointsOfInterest {
		poiPos := w.index(poi.Position)

		// RGB codes. can't remember what the 4th one is
		pix[poiPos*4] = 60
		pix[poiPos*4+1] = 220
		pix[poiPos*4+2] = 255
		pix[poiPos*4+3] = 0xff
	}

}
