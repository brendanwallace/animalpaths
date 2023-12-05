package grid

import (
	"bw/animal_paths/world"
	"container/heap"
	"math"
)

// Linked list:

type LinkedList struct {
	position world.GridPosition
	next     *LinkedList
}

type Item struct {
	path     *LinkedList
	position world.GridPosition
	cost     float64
	priority float64
}

type PriorityQueue []*Item

func (pq *PriorityQueue) Len() int { return len(*pq) }

func (pq *PriorityQueue) Less(i, j int) bool {
	return (*pq)[i].priority < (*pq)[j].priority
}

func (pq *PriorityQueue) Swap(i, j int) {
	(*pq)[i], (*pq)[j] = (*pq)[j], (*pq)[i]
}

func (pq *PriorityQueue) Push(x interface{}) {
	item := x.(*Item)
	*pq = append(*pq, item)
}

func (pq *PriorityQueue) Pop() interface{} {
	item := (*pq)[len(*pq)-1]
	*pq = (*pq)[0 : len(*pq)-1]
	return item
}

// These aren't strictly necessary, but they avoid having a bunch of
// type casting everywhere else:
func initPQ() *PriorityQueue {
	pq := make(PriorityQueue, 0)
	heap.Init(&pq)
	return &pq
}

func push(pq *PriorityQueue, item *Item) {
	heap.Push(pq, item)
}

func pop(pq *PriorityQueue) *Item {
	return heap.Pop(pq).(*Item)
}

// Searching algorithm:

func heuristic(pos, stop world.GridPosition, w *world.World) float64 {
	// xdif := math.Abs(float64(stop.X - pos.X))
	// ydif := math.Abs(float64(stop.Y - pos.Y))

	// return math.Max(xdif, ydif) * MAX_COST

	if w.TORUS {
		xdif := math.Abs(float64(stop.X - pos.X))
		xdif = math.Min(xdif, float64(w.WIDTH)-xdif)
		ydif := math.Abs(float64(stop.Y - pos.Y))
		ydif = math.Min(ydif, float64(w.HEIGHT)-ydif)
		return (xdif + ydif) * w.MIN_COST
	}

	// no diagonals:
	return (math.Abs(float64(stop.X-pos.X)) + math.Abs(float64(stop.Y-pos.Y))) * w.MIN_COST

}

func FindPath(start, stop world.GridPosition, w *world.World) []world.GridPosition {

	priorityQueue := initPQ()
	visited := make(map[world.GridPosition]bool)

	currentPosition := start
	// empty list:
	var currentPath *LinkedList = nil
	currentCost := 0.0
	visited[start] = true

	for currentPosition != stop {

		for _, n := range w.Neighbors(currentPosition) {
			if !visited[n] {
				path := &LinkedList{n, currentPath}
				cost := currentCost + w.Cost(n)
				priority := cost + heuristic(n, stop, w)
				push(priorityQueue, &Item{path, n, cost, priority})
				visited[n] = true
			}
		}
		item := pop(priorityQueue)
		currentPosition = item.path.position
		currentPath = item.path
		currentCost = item.cost
		visited[currentPosition] = true
	}
	// exited the loop - that means currentPosition is `stop` and currentPath
	// is the path to take. we just need to put it into a slice and reverse it

	path := make([]world.GridPosition, 0)
	// Pull all the positions out into the path:
	for ; currentPath != nil; currentPath = currentPath.next {
		path = append(path, currentPath.position)
	}

	// Reverse path:
	for i, j := 0, len(path)-1; i < j; i, j = i+1, j-1 {
		path[i], path[j] = path[j], path[i]
	}
	return path
}
