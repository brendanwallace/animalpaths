package grid

import (
	"bw/animal_paths/world"
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestPriorityQueue(t *testing.T) {
	pq := initPQ()
	push(pq, &Item{nil, world.GridPosition{}, 10.0, 30.0})
	push(pq, &Item{nil, world.GridPosition{}, 10.0, 10.0})
	push(pq, &Item{nil, world.GridPosition{}, 10.0, 20.0})

	assert.Equal(t, 10.0, (pop(pq).priority), "10")
	assert.Equal(t, 20.0, (pop(pq).priority), "20")
	assert.Equal(t, 30.0, (pop(pq).priority), "30")

}

func NewWorld(width, height int) *world.World {
	w := world.World{
		WIDTH:                width,
		HEIGHT:               height,
		FLATTEN_COEFFICIENT:  0.01,
		MAX_COST:             2.0,
		MIN_COST:             1.0,
		RECOVERY_COEFFICIENT: 0.001,
		ANIMALS:              1,
		NEIGHBOR_FLATTEN:     0.2,
		ALL_RANDOM:           true,
		TORUS:                false,
	}
	w.Initialize([]world.Animal{})
	return &w
}

func TestFindPath(t *testing.T) {
	cases := []struct {
		w     *world.World
		start world.GridPosition
		stop  world.GridPosition
		path  []world.GridPosition
	}{
		{
			NewWorld(2, 2),
			world.GridPosition{0, 0},
			world.GridPosition{0, 1},
			[]world.GridPosition{world.GridPosition{0, 1}},
		},
		{
			NewWorld(10, 10),
			world.GridPosition{0, 0},
			world.GridPosition{0, 3},
			[]world.GridPosition{world.GridPosition{0, 1}, world.GridPosition{0, 2}, world.GridPosition{0, 3}},
		},
		{
			NewWorld(10, 10),
			world.GridPosition{0, 0},
			world.GridPosition{3, 0},
			[]world.GridPosition{world.GridPosition{1, 0}, world.GridPosition{2, 0}, world.GridPosition{3, 0}},
		},
		{
			NewWorld(10, 10),
			world.GridPosition{0, 3},
			world.GridPosition{0, 0},
			[]world.GridPosition{world.GridPosition{0, 2}, world.GridPosition{0, 1}, world.GridPosition{0, 0}},
		},
	}

	for _, tt := range cases {
		assert.Equal(t, tt.path, FindPath(tt.start, tt.stop, tt.w), "0, 0 -> 0, 3")
	}
}

func TestFindBigPath(t *testing.T) {

	w := NewWorld(100, 100)
	w.TORUS = true
	assert.Equal(t, 1, len(FindPath(world.GridPosition{0, 99}, world.GridPosition{0, 0}, w)))
}
