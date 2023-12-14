package main

import (
   // #include <stdlib.h>
   "C"
)
import (
   "container/heap"
   "encoding/json"
   "fmt"
   "math"
   "unsafe"
)

// SEARCH CONSTANTS

const RADIAL_INCREMENTS = 8
const STEP_SIZE = 1.0
const FOUND_RADIUS = 0.6
const MIN_COST = 1.0
const Tau = math.Pi * 2

// SHARED DATA TYPES

type Vector struct {
   X, Y float64
}

type Path struct {
   Path []Vector
}

type world struct {
   patches       []float64
   width, height int
}

func (w world) at(x, y int) float64 {
   index := w.width*y + x
   if index >= len(w.patches) || index < 0 {
      return math.Inf(1)
   }
   return w.patches[w.width*y+x]
}

// INPORT EXPORT STUFF

//export Search
func Search(worldPtr *float64, x, y int, startX, startY, endX, endY float64) unsafe.Pointer {
   fmt.Printf("%v, %v, %v, %v, %v, %v", x, y, startX, startY, endX, endY)
   patches := unsafe.Slice(worldPtr, x*y)
   w := world{patches, x, y}
   start := Vector{float64(startX), float64(startY)}
   end := Vector{float64(endX), float64(endY)}

   path := search(w, start, end, RADIAL_INCREMENTS, STEP_SIZE, FOUND_RADIUS, MIN_COST)

   pathJson, _ := json.Marshal(Path{path})

   c := unsafe.Pointer(C.CBytes(pathJson))

   return c
}

//export Free
func Free(p unsafe.Pointer) {
   C.free(p)
}

// PRIORITY QUEUE IMPLEMENTATION

// Linked list:

type LinkedList struct {
   position Vector
   next     *LinkedList
}

type Item struct {
   path     *LinkedList
   position Vector
   cost     float64
   minCost  float64
}

type PriorityQueue []*Item

func (pq *PriorityQueue) Len() int { return len(*pq) }

func (pq *PriorityQueue) Less(i, j int) bool {
   return (*pq)[i].minCost < (*pq)[j].minCost
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

// ACTUAL SEARCH

func distance(v1, v2 Vector) float64 {
   return math.Sqrt(math.Pow(v2.X-v1.X, 2) + math.Pow(v2.Y-v1.Y, 2))
}

func neighbors(start Vector, stepSize float64, increments int) []Vector {

   ns := make([]Vector, increments)
   for i := 0; i < increments; i = i + 1 {
      theta := Tau * float64(i) / float64(increments)
      v := Vector{
         X: start.X + math.Cos(theta)*stepSize,
         Y: start.Y + math.Sin(theta)*stepSize,
      }
      ns[i] = v
   }
   return ns
}

func cost(w world, v1, v2 Vector) float64 {
   x, y := int(v2.X), int(v2.Y)
   return w.at(x, y) * distance(v1, v2)
}

func search(w world, start, end Vector, radialIncrements int, stepSize, foundRadius float64, minCost float64) []Vector {

   pQ := initPQ()

   var currPos Vector = start
   // base case of the LinkedList is a nil pointer - this is an empty path
   var currPath *LinkedList = nil
   var currCost float64

   for distance(currPos, end) > foundRadius {
      for _, n := range neighbors(currPos, stepSize, radialIncrements) {
         nPath := &LinkedList{n, currPath}
         nCost := currCost + cost(w, currPos, n)
         nMinCost := nCost + distance(n, end)*minCost
         push(pQ, &Item{nPath, n, nCost, nMinCost})
      }

      item := pop(pQ)
      currPath = item.path
      currPos = item.position
      currCost = item.cost
   }

   path := make([]Vector, 0)
   // Pull all the positions out into the path:
   for ; currPath != nil; currPath = currPath.next {
      path = append(path, currPath.position)
   }

   // Reverse path:
   for i, j := 0, len(path)-1; i < j; i, j = i+1, j-1 {
      path[i], path[j] = path[j], path[i]
   }
   return path
}

// OTHERWISE UNNECESSARY MAIN FUNCTION REQUIRED TO COMPILE C LIBRARY

func main() {

}
