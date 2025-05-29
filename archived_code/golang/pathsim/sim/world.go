package sim

type World struct {
	settings Settings
	// improvement on each patch.
	Patches [][]float64
}

func NewWorld(settings Settings) *World {
	w := &World{
		settings: settings,
		Patches:  make([][]float64, settings.X),
	}
	for i, _ := range w.Patches {
		w.Patches[i] = make([]float64, settings.Y)
	}
	return w

}

func (w *World) update() {

}
