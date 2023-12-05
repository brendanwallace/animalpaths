package continuous

import (
	"bw/animal_paths/world"
	"math"
	"math/rand"
)

/*
General Behavior Rules:

each animal has a home
each animal chooses a point of interest to visit, and then either returns home
or visits a different point of interest with some (decaying?) probability


World Rules:

(see world.go)


Search rules:



*/

type Animal struct {
	home   *world.PointOfInterest
	target *world.PointOfInterest

	heading  Vector
	position Vector
}

func (a *Animal) GridPosition() world.GridPosition {
	return ConvertToGrid(a.position)
}

func (a *Animal) Move(w *world.World) {
	if a.Arrived() {
		a.NewTarget(w)
	}
	a.ChartHeading(w)
	a.position = a.position.Plus(a.heading.Times(world.ANIMAL_SPEED))
	a.position.x = math.Min(a.position.x, world.WIDTH-1)
	a.position.x = math.Max(0, a.position.x)
	a.position.y = math.Min(a.position.y, world.HEIGHT-1)
	a.position.y = math.Max(0, a.position.y)
	w.FlattenPath(a.GridPosition())
}

func (a *Animal) Arrived() bool {
	if a.target == nil {
		return true
	}
	return a.position.Minus(FromGridPosition(a.target.Position)).Length() <= world.ARRIVED_DISTANCE
}

func (a *Animal) NewTarget(w *world.World) {
	if a.target != a.home && rand.Float64() < world.HOME_PERCENTAGE {
		a.target = a.home
	} else {
		a.target = &w.PointsOfInterest[rand.Intn(len(w.PointsOfInterest))]
	}
}

func (a *Animal) ChartHeading(w *world.World) {
	if world.SEARCH_STRATEGY == world.HEURISTIC_OPTION {
		a.ChartHeadingHeuristic(w)
	} else if world.SEARCH_STRATEGY == world.AVERAGE_OPTION {
		a.ChartHeadingAverage(w)
	} else if world.SEARCH_STRATEGY == world.GRADIENT_OPTION {
		a.ChartHeadingGradient(w)
	}
}

func (a *Animal) ChartHeadingHeuristic(w *world.World) {
	target := FromGridPosition(a.target.Position)
	var bestHeading *Vector = nil
	bestDistance := math.Inf(1)
	start := 0.0
	end := math.Pi * 2
	for angle := start; angle <= end; angle = angle + world.TURN_INTERVAL {
		testHeading := FromRadial(angle, 1.0)
		testDistance := HeuristicCost(
			Segment{a.position, a.position.Plus(testHeading.Times(world.SEARCH_RADIUS))}, target, w)
		if testDistance < bestDistance {
			bestHeading = &testHeading
			bestDistance = testDistance
		}
	}
	a.heading = bestHeading.Unit()
}

func (a *Animal) ChartHeadingAverage(w *world.World) {
	target := FromGridPosition(a.target.Position)
	var bestHeading *Vector = nil
	bestDistance := math.Inf(1)
	start := 0.0
	end := math.Pi * 2
	// Find the "best" direction by finding the cheapest cost segment.
	for angle := start; angle <= end; angle = angle + world.TURN_INTERVAL {
		testHeading := FromRadial(angle, 1.0)
		testDistance := Cost(
			Segment{a.position, a.position.Plus(testHeading.Times(world.SEARCH_RADIUS))}, w)
		if testDistance < bestDistance {
			bestHeading = &testHeading
			bestDistance = testDistance
		}
	}
	bestDirection := bestHeading.Unit()
	targetDirection := target.Minus(a.position).Unit()

	if angleDiff := bestDirection.Angle() - targetDirection.Angle(); angleDiff > math.Pi/2 || angleDiff < -math.Pi/2 {
		a.heading = targetDirection
		return
	}

	// Average the target direction and the "best" direction together
	averageDirection := bestDirection.Plus(targetDirection).Unit()
	a.heading = averageDirection
}

func InitializeAnimals(w *world.World) []world.Animal {
	animals := make([]world.Animal, world.ANIMALS)
	for a := range animals {

		start := Vector{0, 10}
		heading := Vector{rand.Float64(), rand.Float64()}
		animals[a] = &Animal{
			home:     &world.PointOfInterest{world.GridPosition{0, 0}},
			heading:  heading,
			position: start,
		}
	}
	return animals
}
