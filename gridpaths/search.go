package gridpaths

import (
	"container/heap"
	"math"
)

// Linked list:

type LinkedList struct {
	position Position
	next     *LinkedList
}

type Item struct {
	path     *LinkedList
	position Position
	cost     float64
	priority float64
}

type PriorityQueue []*Item

func (pq PriorityQueue) Len() int { return len(pq) }

func (pq PriorityQueue) Less(i, j int) bool {
	return pq[i].priority < pq[j].priority
}

func (pq PriorityQueue) Swap(i, j int) {
	pq[i], pq[j] = pq[j], pq[i]
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

func (w *World) neighbors(p Position) []Position {
	ns := make([]Position, 0)

	if p.x+1 < w.WIDTH || w.TORUS {
		ns = append(ns, Position{(p.x + 1) % w.WIDTH, p.y})
	}
	if p.x-1 >= 0 || w.TORUS {
		ns = append(ns, Position{(w.WIDTH + p.x - 1) % w.WIDTH, p.y})
	}
	if p.y+1 < w.HEIGHT || w.TORUS {
		ns = append(ns, Position{p.x, (p.y + 1) % w.HEIGHT})
	}
	if p.y-1 >= 0 || w.TORUS {
		ns = append(ns, Position{p.x, (w.HEIGHT + p.y - 1) % w.HEIGHT})
	}
	return ns
}

func (w *World) heuristic(pos, stop Position) float64 {
	// xdif := math.Abs(float64(stop.x - pos.x))
	// ydif := math.Abs(float64(stop.y - pos.y))

	// return math.Max(xdif, ydif) * MAX_COST

	if w.TORUS {
		xdif := math.Abs(float64(stop.x - pos.x))
		xdif = math.Min(xdif, float64(w.WIDTH)-xdif)
		ydif := math.Abs(float64(stop.y - pos.y))
		ydif = math.Min(ydif, float64(w.HEIGHT)-ydif)
		return (xdif + ydif) * w.MIN_COST
	}

	// no diagonals:
	return (math.Abs(float64(stop.x-pos.x)) + math.Abs(float64(stop.y-pos.y))) * w.MIN_COST

}

func (w *World) FindPath(start, stop Position) []Position {

	priorityQueue := initPQ()
	visited := make(map[Position]bool)

	currentPosition := start
	// empty list:
	var currentPath *LinkedList = nil
	currentCost := 0.0
	visited[start] = true

	for currentPosition != stop {

		for _, n := range w.neighbors(currentPosition) {
			if !visited[n] {
				path := &LinkedList{n, currentPath}
				cost := currentCost + w.Cost(n)
				priority := cost + w.heuristic(n, stop)
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

	path := make([]Position, 0)
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
