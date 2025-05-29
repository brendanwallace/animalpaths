import numpy as np

from . import pysearch
from . import gosearch
from . import util

# We just import this to get access to the world constants like min/max cost
# that A-star needs.
from . import world as world_consts

TAU : float = np.pi * 2

## A* Search Parameters
ASTAR_GO = True

# How many directions to search.
# E.g. if this is 180, then it considers 2 degree angles.
RADIAL_INCREMENTS = 36
STEP_SIZE = 1.0
FOUND_RADIUS = 1.0
MIN_COST = 1.0
PRECISION = 1.5
PESSIMISM = 0.0




# Speed is specifically distance traveled per frame. 
SPEED : float = 1.0
ARRIVED_DISTANCE : float = 1.0 * SPEED

# If the speed is kind of high, then we can allocate path erosion more
# smoothly by chopping up our steps into smaller steps.
NUM_STEPS_PER_MOVE : int = 1

class Animal():
	"""Abstract class that all animals should inherit from."""

	def __init__(self, scenario, world, position):
		self.scenario = scenario
		self.world = world
		self.position = position
		self.target = None
		self.origin = None
		self.trip_cost = 0.0


	def handle_arrived(self):
		"""
		Chooses a new target.

		Assumes there are at least 2 viable locations.
		"""
		self.scenario.handle_arrived(self)

	def move(self):
		raise NotImplementedError

	def arrived(self):
		return np.linalg.norm(self.position - self.target.position) <= ARRIVED_DISTANCE

	def orient(self):
		"""
		Orient should check if we arrived at our target, and if so find a new
		target.
		"""
		raise NotImplementedError


	def update(self):
		self.orient()
		self.trip_cost += self.move()
		self.world.improve_patch(self.position)


class AStar(Animal):
	"""
	This is the smart animal that uses A* search to navigate to its target.
	"""

	def __init__(self, *args):
		super().__init__(*args)
		self.path = []


	def arrived(self):
		return len(self.path) == 0 or super().arrived()


	def orient(self):
		"""
		We only need to chart a path if we reached our last target.

		This can lead to not moving for a step if we accidentally choose a target
		we were already at or that is 0 steps away.
		"""
		if self.target is None or self.arrived():
			self.handle_arrived()
			if ASTAR_GO:
				self.path = gosearch.a_star(
					self.world,
					self.position,
					self.target.position,
					RADIAL_INCREMENTS, STEP_SIZE,
					FOUND_RADIUS, world_consts.MIN_COST,
					PRECISION, PESSIMISM,
				)
				# print("\ngoing to ", self.target.position, " from ", self.position)

			else:
				self.path = pysearch.a_star(
					self.world,
					self.position,
					self.target.position,
					self.world.width, self.world.height, world_consts.MIN_COST)

	def move(self):
		if len(self.path) > 0:
			next = self.path.pop(0)
			cost = self.scenario.world.cost_between(self.position, next)
			self.position = next
			return cost
		else:
			print(f"{self} didn't move - we must have chosen a target we were already at")
			return 0.0



 


class DirectWalker(Animal):

	DIRECTIONAL_VARIANCE = 0.01

	def __init__(self, *args):
		super().__init__(*args)

		angle = np.random.rand() * TAU
		self.heading = np.array([np.cos(angle), np.sin(angle)])

	def move(self):
		self.position = self.position + self.heading * SPEED

	def orient(self):

		if self.target is None or self.arrived():
			self.handle_arrived()

		self.heading = util.normalize(self.target.position - self.position)

		# rotate by a normally distributed angle
		angle = np.random.normal(0, self.DIRECTIONAL_VARIANCE) * TAU
		self.heading = util.rotate(self.heading, angle)

		# # wrap around (periodic boundary conditions)
		# self.position = np.mod(self.position, [World.WIDTH, World.HEIGHT])






class Gradient(Animal):
	# number of angles to check when sensing local path comfort
	ANGLE_FREQUENCY = 120
	# radii to check when sensing local path comfort
	RADII = [1.0, 2.0, 3.0]

	COMFORT_WEIGHT = 0.4


	def __init__(self, *args):
		super().__init__(*args)

		angle = np.random.rand() * TAU
		self.heading = np.array([np.cos(angle), np.sin(angle)])


	def orient(self):

		# Acquire a new target randomly
		if self.target is None or self.arrived():
			self.handle_arrived()

		target_direction = util.normalize(self.target.position - self.position)


		comfort_direction = np.array([0.0, 0.0])
		for radius in self.RADII:
			for angle in range(self.ANGLE_FREQUENCY):
				theta = TAU * float(angle) / float(self.ANGLE_FREQUENCY)
				relative_vec = radius * np.array([np.cos(theta), np.sin(theta)])
				test_position = self.position + relative_vec
				comfort = self.world.comfort_at(test_position)  * np.exp(-1.0 * radius)
				# this turns it into a gradient approximation:
				comfort_direction += (comfort) * relative_vec / float(self.ANGLE_FREQUENCY / 2.0)
				#print(radius, angle, theta, relative_vec)

		# normalize comfort_direction
		comfort_direction = util.normalize(comfort_direction)

		direction = self.COMFORT_WEIGHT * comfort_direction + (1.0 - self.COMFORT_WEIGHT) * target_direction


		self.heading = util.normalize(direction)

	def move(self):
		self.position += self.heading * SPEED

