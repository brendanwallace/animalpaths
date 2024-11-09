package continuous

import (
	"bw/animal_paths/world"
	"math"
)

const SIGMA = 1.0

func inBounds(p Vector) bool {
	return p.x >= 0 && p.x < world.WIDTH && p.y >= 0 && p.y < world.HEIGHT
}

func (a *Animal) ChartHeadingGradient(w *world.World) {
	// search around the position in a big square
	target := FromGridPosition(a.target.Position)
	currentPosition := a.position

	targetD := target.Minus(currentPosition)
	targetDirection := targetD.Angle()

	radii := []float64{1.0}

	start, end := -0.5*math.Pi, 0.5*math.Pi
	angleIncrement := math.Pi / 20

	directionSum := Vector{}
	// search each of these radii
	for _, radius := range radii {
		// radial increments
		for angle := start; angle <= end; angle = angle + angleIncrement {
			searchAngle := targetDirection + angle
			searchPosition := currentPosition.Plus(FromRadial(searchAngle, radius))
			pathQuality := w.Comfort(ConvertToGrid(searchPosition))
			weight := (pathQuality + math.Cos(angle)) / radius
			directionSum = directionSum.Plus(FromRadial(searchAngle, weight))
		}
	}
	a.heading = directionSum.Unit()
}

func weightFunction(l float64) float64 {
	return math.Exp(-l / SIGMA)
}
