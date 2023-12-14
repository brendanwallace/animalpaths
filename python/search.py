import numpy as np
import queue
import pytest
import itertools


TAU = 2*np.pi


RADIAL_INCREMENTS = 180
STEP_SIZE = 1.0
FOUND_RADIUS = 1.0

def distance_between(p1, p2):
	return np.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)
	#return np.linalg.norm(p1 - p2)


def test_distance_between():
	np.testing.assert_almost_equal(
		## 3, 4, 5 triangle
		distance_between(np.array([0, 0]), np.array([3, 4])), 5.0)

def heuristic_cost(start, end, min_cost):
	"""
	heuristic_cost returns the minimum possible traversal cost between
	`start` and `end`, i.e. it's the heuristic for A* search

	Fortunately this is pretty straightforward. There's a
	known minimum cost and we use that.
	"""
	return distance_between(start, end) * min_cost

def cost(start, end, cost_at):
	"""
	Counts the cost of traversing *into* a square
	

	This is safer than doing it at the start, because this way we can avoid
	walking off the end of the world.
	""" 
	return distance_between(start, end) * cost_at(end)

class TestCost:

	def test_distance_one(self):
		assert(cost(np.array([0, 0]), np.array([0, 1]), (lambda p: 1.0)) == 1)

	def test_distance_10(self):
		assert(cost(np.array([0, 0]), np.array([10, 0]), (lambda p: 1.0)) == 10)


def neighbor_points(point, step_size, radial_increments):
	neighbor_points = []
	for i in range(radial_increments):
		angle = i * TAU / radial_increments
		diff = step_size * np.array([np.cos(angle), np.sin(angle)])
		neighbor_points.append(point + diff)
	return neighbor_points

class TestNeighborPoints:

	def test_2_points(self):
		np.testing.assert_array_almost_equal(
			np.array(neighbor_points(np.array([0, 0]), 1.0, 2)),
			np.array([[1, 0], [-1, 0]]))


	def test_table(self):
		for _input, _expected in [
			# start by zero, and go right + left
			(([0, 0], 1.0, 2), [[1, 0], [-1, 0]]),

			# up, down, right, left
			(([0, 0], 1.0, 4), [[1, 0], [0, 1], [-1, 0], [0, -1]]),

			# offset by 2
			(([2, 0], 1.0, 2), [[3, 0], [1, 0]]),
		]:
			start, step_size, increments = _input
			actual = neighbor_points(np.array(start), step_size, increments)
			expected = np.array(_expected)
			np.testing.assert_array_almost_equal(actual, expected)



def a_star(world, start, target):


	# use this for a star search
	pqueue = queue.PriorityQueue()

	# define this function for the cost
	def cost_at(point):
		return world.cost_at(point)


	current_point, current_cost, current_path = start, 0, []

	_tiebreak = 0

	while distance_between(current_point, target) > FOUND_RADIUS:
		

		# neighbors are the places we can head from our current location
		# first add all next possible steps, computing real and heuristic distances
		for n in neighbor_points(current_point, STEP_SIZE, RADIAL_INCREMENTS):
			_cost = current_cost + cost(current_point, target, cost_at)
			_path = current_path + [n]
			_hcost = heuristic_cost(n, target, world.MIN_COST)
			#print(_hcost, _path, _cost)
			pqueue.put((_hcost, _tiebreak, (n, _cost, _path)))
			_tiebreak += 1


		# then go to the next point
		#print("about to get")
		_, __, (current_point, current_cost, current_path) = pqueue.get()


		#print("current_point:", current_point)

	return current_path

#print(a_star(world.World(), np.array([0, 0]), np.array([0, 1000.0001])))

