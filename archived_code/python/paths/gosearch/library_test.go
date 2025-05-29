package main

import (
	"fmt"
	"math"
	"testing"
)

type V = Vector

const TOL = 0.001

func almostEqual(v1, v2 Vector) bool {
	return (math.Abs(v1.X-v2.X) <= TOL && math.Abs(v1.Y-v2.Y) <= TOL)
}

func TestDistance(t *testing.T) {

	tests := []struct {
		want float64
		v1   Vector
		v2   Vector
	}{
		{
			want: 1.0,
			v1:   Vector{0.0, 0.0},
			v2:   Vector{1.0, 0.0},
		},
		{
			want: math.Sqrt(2),
			v1:   Vector{0.0, 0.0},
			v2:   Vector{1.0, 1.0},
		},
	}

	for _, tt := range tests {
		got := distance(tt.v1, tt.v2)
		if math.Abs(got-tt.want) > TOL {
			t.Errorf("distance(%v, %v) = %v, want %v", tt.v1, tt.v2, got, tt.want)
		}

	}

}

func TestNeighbors(t *testing.T) {

	tests := []struct {
		want       []Vector
		start      Vector
		stepSize   float64
		increments int
	}{
		{
			want:       []Vector{Vector{1.0, 0.0}},
			start:      Vector{0.0, 0.0},
			stepSize:   1.0,
			increments: 2,
		},
		{
			want:       []Vector{Vector{2.0, 0.0}, Vector{0.0, 0.0}},
			start:      Vector{1.0, 0.0},
			stepSize:   1.0,
			increments: 2,
		},
		{
			want:       []Vector{Vector{1.0, 0.0}, Vector{0.0, 1.0}},
			start:      Vector{0.0, 0.0},
			stepSize:   1.0,
			increments: 4,
		},
	}

	for _, tt := range tests {

		got := neighbors(tt.start, tt.stepSize, tt.increments)
		if !(len(got) == len(tt.want)) {
			t.Errorf(fmt.Sprintf("lengths don't match. got %v, want %v", got, tt.want))
		}
		for i := range got {
			if !almostEqual(got[i], tt.want[i]) {
				t.Errorf(fmt.Sprintf("not equal at %d. got %v, want %v", i, got, tt.want))
			}
		}
	}

}

func TestSearchSquareMoves(t *testing.T) {

	w := world{
		patches: []float64{
			2.0, 2.0, 2.0, 2.0,
			2.0, 2.0, 2.0, 2.0,
			2.0, 2.0, 2.0, 2.0,
			2.0, 2.0, 2.0, 2.0,
		},
		width:  4,
		height: 4,
	}

	tests := []struct {
		expected          []Vector
		start             Vector
		end               Vector
		radial_increments int
		step_size         float64
		found_radius      float64
		min_cost          float64
	}{
		{
			expected:          []Vector{Vector{1, 0}},
			start:             Vector{0, 0},
			end:               Vector{1, 0},
			radial_increments: 2,
			step_size:         1.0,
			found_radius:      0.5,
			min_cost:          1.0,
		},
		{
			expected:          []Vector{Vector{1, 0}, Vector{2, 0}, Vector{3, 0}},
			start:             Vector{0, 0},
			end:               Vector{3, 0},
			radial_increments: 2,
			step_size:         1.0,
			found_radius:      0.5,
			min_cost:          1.0,
		},
		{
			expected:          []Vector{Vector{1, 0}},
			start:             Vector{0, 0},
			end:               Vector{1, 0},
			radial_increments: 4,
			step_size:         1.0,
			found_radius:      0.5,
			min_cost:          1.0,
		},
		{
			expected:          []Vector{Vector{0, 1}},
			start:             Vector{0, 0},
			end:               Vector{0, 1},
			radial_increments: 4,
			step_size:         1.0,
			found_radius:      0.5,
			min_cost:          1.0,
		},
		{
			expected:          []Vector{Vector{0, 1}},
			start:             Vector{0, 0},
			end:               Vector{0, 1},
			radial_increments: 4,
			step_size:         1.0,
			found_radius:      0.5,
			min_cost:          1.0,
		},

		// Start from 1, 1 and go to 0, 0
		{
			expected:          []Vector{Vector{0, 1}, V{0, 0}}, // {1, 0} or {0, 1} would have been OK here
			start:             Vector{1, 1},
			end:               Vector{0, 0},
			radial_increments: 4,
			step_size:         1.0,
			found_radius:      0.5,
			min_cost:          1.0,
		},

		{
			expected:          []Vector{Vector{1.0 / math.Sqrt(2), 1.0 / math.Sqrt(2)}, Vector{math.Sqrt(2), math.Sqrt(2)}},
			start:             Vector{0, 0},
			end:               Vector{math.Sqrt(2), math.Sqrt(2)},
			radial_increments: 8,
			step_size:         1.0,
			found_radius:      0.5,
			min_cost:          1.0,
		},
	}

	for _, tt := range tests {

		got := search(w, tt.start, tt.end, tt.radial_increments, tt.step_size, tt.found_radius, tt.min_cost)
		if !(len(got) == len(tt.expected)) {
			t.Errorf(fmt.Sprintf("path lengths don't match. got %v, want %v", got, tt.expected))
			t.Errorf(fmt.Sprintf("search from %v to %v", tt.start, tt.end))
		}
		for i := range got {
			if !almostEqual(got[i], tt.expected[i]) {
				t.Errorf(fmt.Sprintf("not equal at %d. got %v, want %v", i, got, tt.expected))
			}
		}

	}
}

func TestSearchCosts(t *testing.T) {

	w := world{
		patches: []float64{
			1, 2, 2, 2,
			1, 1, 1, 1,
			2, 2, 2, 1,
			2, 2, 2, 1,
		},
		width:  4,
		height: 4,
	}

	tests := []struct {
		expected          []Vector
		start             Vector
		end               Vector
		radial_increments int
		step_size         float64
		found_radius      float64
		min_cost          float64
	}{
		{
			expected:          []V{V{0, 1}, V{1, 1}, V{2, 1}, V{3, 1}, V{3, 2}, V{3, 3}},
			start:             Vector{0, 0},
			end:               Vector{3, 3},
			radial_increments: 4,
			step_size:         1.0,
			found_radius:      0.5,
			min_cost:          1.0,
		},
	}

	for _, tt := range tests {

		got := search(w, tt.start, tt.end, tt.radial_increments, tt.step_size, tt.found_radius, tt.min_cost)
		if !(len(got) == len(tt.expected)) {
			t.Errorf(fmt.Sprintf("path lengths don't match. got %v, want %v", got, tt.expected))
		}
		for i := range got {
			if !almostEqual(got[i], tt.expected[i]) {
				t.Errorf(fmt.Sprintf("not equal at %d. got %v, want %v", i, got, tt.expected))
			}
		}

	}
}
