package main

import (
	"bw/animal_paths/gridpaths"
	"log"

	"github.com/hajimehoshi/ebiten/v2"
)

type Game struct {
	world  *gridpaths.World
	pixels []byte
}

type World interface {
	Width() float64 {
		return 


}

func (g *Game) Update() error {
	g.world.Update()
	return nil
}

func (g *Game) Draw(screen *ebiten.Image) {
	if g.pixels == nil {
		g.pixels = make([]byte, g.world.WIDTH*g.world.HEIGHT*4)
	}
	g.world.Draw(g.pixels)
	screen.WritePixels(g.pixels)
}

func (g *Game) Layout(outsideWidth, outsideHeight int) (int, int) {
	return g.world.WIDTH, g.world.HEIGHT
}

func main() {

	w := &gridpaths.World{
		WIDTH:                300,
		HEIGHT:               300,
		FLATTEN_COEFFICIENT:  0.001,
		MAX_COST:             2.0,
		MIN_COST:             1.0,
		RECOVERY_COEFFICIENT: 0.001,
		ANIMALS:              100,
		NEIGHBOR_FLATTEN:     0.9,
		ALL_RANDOM:           false,
		TORUS:                false,
	}

	// Necessary to initialize the internal state
	w.Initialize()

	g := &Game{world: w}

	ebiten.SetMaxTPS(60)
	ebiten.SetWindowSize(w.WIDTH*2, w.HEIGHT*2)
	ebiten.SetWindowTitle("animal paths")
	if err := ebiten.RunGame(g); err != nil {
		log.Fatal(err)
	}
}
