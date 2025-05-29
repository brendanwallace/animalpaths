package continuous

import (
	"bw/animal_paths/world"
	"math"
)

// Vector is the location in continuous space
type Vector struct {
	x, y float64
}

func (v1 Vector) Plus(v2 Vector) Vector {
	return Vector{v1.x + v2.x, v1.y + v2.y}
}

func (v1 Vector) Minus(v2 Vector) Vector {
	return Vector{v1.x - v2.x, v1.y - v2.y}
}

func (v1 Vector) Times(t float64) Vector {
	return Vector{v1.x * t, v1.y * t}
}

func (v1 Vector) Length() float64 {
	return math.Sqrt(math.Pow(v1.x, 2) + math.Pow(v1.y, 2))
}

func (v1 Vector) Unit() Vector {
	l := v1.Length()
	return Vector{v1.x / l, v1.y / l}
}

func (v1 Vector) Angle() float64 {
	return math.Atan(v1.y / v1.x)
}

func FromRadial(angle, length float64) Vector {
	return Vector{length * math.Cos(angle), length * math.Sin(angle)}
}

func FromGridPosition(grid world.GridPosition) Vector {
	return Vector{float64(grid.X), float64(grid.Y)}
}
