import numpy as np
import queue
import pytest
import itertools

from . import util


TAU = 2*np.pi


RADIAL_INCREMENTS = 36
STEP_SIZE = 1.0
FOUND_RADIUS = 0.5
VISITED_PRECISION = 1


def heuristic_cost(start, end, min_cost):
	"""
	heuristic_cost returns the minimum possible traversal cost between
	`start` and `end`, i.e. it's the heuristic for A* search

	Fortunately this is pretty straightforward. There's a
	known minimum cost and we use that.
	"""
	return util.distance_between(start, end) * min_cost


def neighbor_points(point, step_size, radial_increments, width, height):
	neighbor_points = []
	for i in range(radial_increments):
		angle = i * TAU / radial_increments
		diff = step_size * np.array([np.cos(angle), np.sin(angle)])
		n = point + diff
		if n[0] >= width or n[0] < 0 or n[1] >= height or n[1] < 0:
			continue
		else:
			neighbor_points.append(n)
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

def truncate(v) -> (int, int):
	return (int(v[0] * VISITED_PRECISION), int(v[1] * VISITED_PRECISION))


def a_star(world, start, target, width, height, min_cost):


	# use this for A* search
	pqueue = queue.PriorityQueue()

	visited = set()

	pqueue.put((0, 0, (start, 0, [])))



	current_point, current_cost, current_path = start, 0, []
	#visited.add(truncate(current_point))

	_tiebreak = 0
	i = 0

	while util.distance_between(current_point, target) > FOUND_RADIUS and pqueue.qsize():
		

		# neighbors are the places we can head from our current location
		# first add all next possible steps, computing real and heuristic distances

		if truncate(current_point) not in visited:
			visited.add(truncate(current_point))

			for n in neighbor_points(current_point, STEP_SIZE, RADIAL_INCREMENTS, width, height):
				truncated = truncate(n)
				if truncated not in visited:
					_cost = current_cost + util.distance_between(current_point, n) * world.cost_at(n)
					_path = current_path + [n]
					_hcost = _cost + heuristic_cost(n, target, min_cost)
					#print(_hcost, _path, _cost)
					pqueue.put((_hcost, _tiebreak, (n, _cost, _path)))
					#visited.add(truncate(n))
					_tiebreak += 1


		# then go to the next point
		#print("about to get")
		_, __, (current_point, current_cost, current_path) = pqueue.get()

		#print("popped {}".format(current_point))
		#print("\rvisited: {} queue: {}           ".format(len(visited), pqueue.qsize()), end='')


	return current_path

#print(a_star(world.World(), np.array([0, 0]), np.array([0, 1000.0001])))

