package sim

import "math/rand"

func randomPosition(settings Settings) Position {
	return Position{
		rand.Float64() * float64(settings.X),
		rand.Float64() * float64(settings.Y)}
}
