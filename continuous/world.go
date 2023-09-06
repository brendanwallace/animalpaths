package continuous

/*

Rules:

each animal has a home
each animal chooses a point of interest to visit, and then either returns home
or visits a different point of interest with some (decaying?) probability


*/

type Vector struct {
	x, y float64
}

type PointOfInterest struct {
	position Vector
}

type Animal struct {
	position Vector
	heading  Vector
	home     Vector
}

type Patch struct {
}

type World struct {
	patches []*Patch
	animals []*Animal

	// shared points of interest
	pointsOfInterest []*PointOfInterest
}
