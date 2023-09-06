package gridpaths

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestPriorityQueue(t *testing.T) {
	pq := initPQ()
	push(pq, &Item{nil, Position{}, 10.0, 30.0})
	push(pq, &Item{nil, Position{}, 10.0, 10.0})
	push(pq, &Item{nil, Position{}, 10.0, 20.0})

	assert.Equal(t, 10.0, (pop(pq).priority), "10")
	assert.Equal(t, 20.0, (pop(pq).priority), "20")
	assert.Equal(t, 30.0, (pop(pq).priority), "30")

}

func NewWorld(width, height int) *World {
	w := World{
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
	w.Initialize()
	return &w
}

func TestFindPath(t *testing.T) {
	cases := []struct {
		w     *World
		start Position
		stop  Position
		path  []Position
	}{
		{
			NewWorld(2, 2),
			Position{0, 0},
			Position{0, 1},
			[]Position{Position{0, 1}},
		},
		{
			NewWorld(10, 10),
			Position{0, 0},
			Position{0, 3},
			[]Position{Position{0, 1}, Position{0, 2}, Position{0, 3}},
		},
		{
			NewWorld(10, 10),
			Position{0, 0},
			Position{3, 0},
			[]Position{Position{1, 0}, Position{2, 0}, Position{3, 0}},
		},
		{
			NewWorld(10, 10),
			Position{0, 3},
			Position{0, 0},
			[]Position{Position{0, 2}, Position{0, 1}, Position{0, 0}},
		},
	}

	for _, tt := range cases {
		assert.Equal(t, tt.path, tt.w.FindPath(tt.start, tt.stop), "0, 0 -> 0, 3")
	}
}

func TestFindBigPath(t *testing.T) {

	w := NewWorld(100, 100)
	w.TORUS = true
	assert.Equal(t, 1, len(w.FindPath(Position{0, 99}, Position{0, 0})))
}
