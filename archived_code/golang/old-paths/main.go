package main

import (
	"bw/animal_paths/world"
	"bw/animal_paths/world/continuous"
	"log"

	"github.com/hajimehoshi/ebiten/v2"
)

type Game struct {
	world  *world.World
	pixels []byte
}

func (g *Game) Update() error {
	g.world.Update()
	return nil
}

func (g *Game) Draw(screen *ebiten.Image) {
	if g.pixels == nil {
		g.pixels = make([]byte, world.WIDTH*world.HEIGHT*4)
	}
	g.world.Draw(g.pixels)
	screen.WritePixels(g.pixels)
}

func (g *Game) Layout(outsideWidth, outsideHeight int) (int, int) {
	return world.WIDTH, world.HEIGHT
}

func main() {

	w := &world.World{}

	// Necessary to initialize the internal state
	w.Initialize(continuous.InitializeAnimals(w))
	//INITIAL_STEPS := 1000
	//for i := 0; i < INITIAL_STEPS; i++ {
	//	w.Update()
	//}

	g := &Game{world: w}

	ebiten.SetTPS(60)
	ebiten.SetWindowSize(world.WIDTH*2, world.HEIGHT*2)
	ebiten.SetWindowTitle("animal paths")
	if err := ebiten.RunGame(g); err != nil {
		log.Fatal(err)
	}
}
