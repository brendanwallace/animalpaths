package continuous

import (
	"bw/animal_paths/world"
	"github.com/stretchr/testify/assert"
	"testing"
)

func NewWorld(width, height int) *world.World {
	w := world.World{
		WIDTH:                width,
		HEIGHT:               height,
		FLATTEN_COEFFICIENT:  0.01,
		RECOVERY_COEFFICIENT: 0.001,
		ANIMALS:              1,
		NEIGHBOR_FLATTEN:     0.2,
		ALL_RANDOM:           true,
		TORUS:                false,
	}
	w.Initialize([]world.Animal{})
	return &w
}

func TestCostDs(t *testing.T) {

	delta := 0.1

	cases := []struct {
		world        *world.World
		segment      Segment
		expectedCost float64
	}{
		{NewWorld(100, 100), Segment{Vector{0.0, 0.0}, Vector{0.0, 1.0}}, 2.0},
	}
	for _, tt := range cases {
		actualCost := costDs(tt.segment, tt.world)
		assert.InDelta(t, actualCost, tt.expectedCost, delta)
	}
}

func TestCost(t *testing.T) {

	delta := INFINITESIMAL_LENGTH * world.MAX_COST

	cases := []struct {
		world        *world.World
		segment      Segment
		expectedCost float64
	}{
		{NewWorld(100, 100), Segment{Vector{0.0, 0.0}, Vector{0.0, 1.0}}, 2.0},
		{NewWorld(100, 100), Segment{Vector{0.0, 0.0}, Vector{10.0, 0.0}}, 20.0},
		{NewWorld(100, 100), Segment{Vector{0.0, 0.0}, Vector{12.34, 0.0}}, 24.68},
	}
	for _, tt := range cases {
		actualCost := Cost(tt.segment, tt.world)
		assert.InDelta(t, actualCost, tt.expectedCost, delta)
	}
}

func TestHeuristicCost(t *testing.T) {

	delta := INFINITESIMAL_LENGTH * world.MAX_COST
	testWorld := NewWorld(100, 100)

	cases := []struct {
		segment      Segment
		target       Vector
		expectedCost float64
	}{
		{Segment{Vector{0.0, 0.0}, Vector{0.0, 1.0}}, Vector{0.0, 2.0}, 4.0},
	}
	for _, tt := range cases {
		actualCost := HeuristicCost(tt.segment, tt.target, testWorld)
		assert.InDelta(t, actualCost, tt.expectedCost, delta)
	}
}
