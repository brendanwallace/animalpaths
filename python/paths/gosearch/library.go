package main

import (
   // #include <stdlib.h>
   "C"
)
import (
   "container/heap"
   "encoding/json"
   "log"
   "math"
   "unsafe"
)

// To compile, run:
// go build -buildmode=c-shared -o library.so library.go

const Tau = math.Pi * 2

// SEARCH CONSTANTS

// const RADIAL_INCREMENTS = 72
// const STEP_SIZE = 1.0
// const FOUND_RADIUS = 0.5
// const MIN_COST = 1.0
// const PRECISION = 1
// const PESSIMISM = 0.0

// SHARED DATA TYPES

type Vector struct {
   X, Y float64
}

type Path struct {
   Path []Vector
}

type world struct {
   patches       []float64
   height, width int
}

func (w world) at(x, y int) float64 {

   // cost of going off the world is infinity
   if x < 0 || y < 0 || x >= w.width || y >= w.height {
      return math.Inf(1)
   }

   index := w.width*y + x
   // this should be impossible to get to, but just in case?
   if index >= len(w.patches) || index < 0 {
      log.Fatal("index out of range in world.at")
      return math.Inf(1)
   }
   return w.patches[w.width*y+x]
}

// IMPORT EXPORT STUFF

//export Search
func Search(worldPtr *float64, height, width int, startX, startY, endX, endY float64,
   RADIAL_INCREMENTS int,
   STEP_SIZE, FOUND_RADIUS, MIN_COST, PRECISION, PESSIMISM float64) unsafe.Pointer {
   patches := unsafe.Slice(worldPtr, width*height)
   w := world{patches, height, width}
   start := Vector{float64(startX), float64(startY)}
   end := Vector{float64(endX), float64(endY)}

   path := search(w, start, end, RADIAL_INCREMENTS, STEP_SIZE, FOUND_RADIUS, MIN_COST, PRECISION, PESSIMISM)

   pathJson, _ := json.Marshal(Path{path})
   // Appends null terminating character so python json knows when the byte string ends.
   pathJson = append(pathJson, '\000')

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

func neighbors(start Vector, stepSize float64, increments int, w world) []Vector {

   var ns []Vector
   for i := 0; i < increments; i = i + 1 {
      theta := Tau * float64(i) / float64(increments)
      n := Vector{
         X: start.X + math.Cos(theta)*stepSize,
         Y: start.Y + math.Sin(theta)*stepSize,
      }
      x, y := int(n.X), int(n.Y)
      if x >= 0 && y >= 0 && x < w.width && y < w.height {
         ns = append(ns, n)
      }
   }
   return ns
}

func cost(w world, v1, v2 Vector) float64 {
   x1, y1 := int(v1.X), int(v1.Y)
   x2, y2 := int(v2.X), int(v2.Y)
   return (w.at(x1, y1) + w.at(x2, y2)) * distance(v1, v2) / 2.0
}

type RoundVector struct {
   x, y int
}

type Visited struct {
   log       map[RoundVector]bool
   precision float64
}

func (visited Visited) add(v Vector) {
   rv := RoundVector{int(v.X * visited.precision), int(v.Y * visited.precision)}
   visited.log[rv] = true
}

func (visited Visited) has(v Vector) bool {
   rv := RoundVector{int(v.X * visited.precision), int(v.Y * visited.precision)}
   return visited.log[rv]
}

func search(w world, start, end Vector, radialIncrements int, stepSize,
   foundRadius float64, minCost float64, precision float64, pessimism float64) []Vector {

   // log.Printf("\nsearching from start:%v to end:%v\n", start, end)
   // // log.Printf("\nworld: %v", w)

   pQ := initPQ()

   var currPos Vector = start
   // base case of the LinkedList is a nil pointer - this is an empty path
   var currPath *LinkedList = nil
   var currCost float64

   numVisited := 0
   numQueued := 0

   visited := Visited{log: make(map[RoundVector]bool), precision: precision}

   for distance(currPos, end) > foundRadius {

      if !visited.has(currPos) {
         visited.add(currPos)

         // log.Printf("neighbors: %v\n", neighbors(currPos, stepSize, radialIncrements))

         for _, n := range neighbors(currPos, stepSize, radialIncrements, w) {
            // log.Printf("considering neighber %v\n", n)
            if !visited.has(n) {
               nPath := &LinkedList{n, currPath}
               nCost := currCost + cost(w, currPos, n)
               nMinCost := nCost + distance(n, end)*minCost*(1.0+pessimism)
               item := Item{nPath, n, nCost, nMinCost}
               // log.Printf("adding item %v\n", item)
               push(pQ, &item)
               numQueued = numQueued + 1
            }
         }
      }

      // Pop it from the queue.
      item := pop(pQ)

      numVisited = numVisited + 1
      currPath = item.path
      currPos = item.position
      currCost = item.cost
      // log.Printf("currently at: %v, num visited: %v, num queued: %v\n", currPos, numVisited, numQueued)
      // log.Printf("distance(currPos, end) > foundRadius = %v\n", distance(currPos, end) > foundRadius)

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

   // log.Printf("\npath found: %v", path)

   return path
}

// OTHERWISE UNNECESSARY MAIN FUNCTION REQUIRED TO COMPILE C LIBRARY

func main() {

}
