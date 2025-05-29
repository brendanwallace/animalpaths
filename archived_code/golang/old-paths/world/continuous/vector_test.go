package continuous

import (
	"github.com/stretchr/testify/assert"
	"math"
	"testing"
)

func TestFromRadial(t *testing.T) {

	delta := 0.000001

	cases := []struct {
		angle     float64
		length    float64
		expectedX float64
		expectedY float64
	}{
		{0, 1.0, 1.0, 0.0},
		{math.Pi / 2, 1.0, 0.0, 1.0},
		{math.Pi, 10.0, -10.0, 0.0},
	}
	for _, tt := range cases {
		actual := FromRadial(tt.angle, tt.length)
		assert.InDelta(t, actual.x, tt.expectedX, delta)
		assert.InDelta(t, actual.y, tt.expectedY, delta)
	}
}

func TestLength(t *testing.T) {
	delta := 0.001
	cases := []struct {
		segment        Segment
		expectedLength float64
	}{
		{Segment{Vector{0, 0}, Vector{0, 1}}, 1.0},
		{Segment{Vector{0, 1}, Vector{0, 0}}, 1.0},
	}
	for _, tt := range cases {
		assert.InDelta(t, tt.segment.Vector().Length(), tt.expectedLength, delta)
	}
}
