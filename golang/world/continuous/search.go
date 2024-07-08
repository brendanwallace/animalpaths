package continuous

import (
	"bw/animal_paths/world"
	"math"
)

const INFINITESIMAL_LENGTH = 0.1

func ConvertToGrid(c Vector) world.GridPosition {
	// casting a float to an int drops the decimals - always rounds down
	// as desired.
	return world.GridPosition{X: int(c.x), Y: int(c.y)}
}

// costDs returns the cost of a small segment - it assumes
// the cost of the entire segment is equal to the cost of the
// start of it.
func costDs(ds Segment, w *world.World) float64 {
	cost := w.Cost(ConvertToGrid(ds.start))
	length := ds.Vector().Length()
	return cost * length
}

// Cost computes the cost of traversing segment `s` across world `w`
//
// Cost does not compute this exactly. This is probably possible with
// some nice geometry - but it seems a lot more complicated. Here we
// take an iterative approximate approach.
func Cost(s Segment, w *world.World) float64 {
	unitDiff := s.Vector().Unit()
	totalLength := s.Vector().Length()
	v := totalLength / INFINITESIMAL_LENGTH
	numSteps := int(math.Round(v))
	cost := 0.0
	t := 0.0
	for i := 0; i < numSteps; i++ {
		t = t + INFINITESIMAL_LENGTH
		ds := Segment{s.start.Plus(unitDiff.Times(t)), s.start.Plus(unitDiff.Times(t + INFINITESIMAL_LENGTH))}
		cost += costDs(ds, w)
	}
	return cost
}

// HeuristicCost computes a heuristic cost of traveling to `target`
// via segment `s`.
func HeuristicCost(s Segment, target Vector, w *world.World) float64 {
	// actual cost of the known segment
	known := Cost(s, w)
	// worst case straight line to the target from the end of the s
	toTarget := world.MAX_COST * s.end.Minus(target).Length()
	return known + toTarget
}
