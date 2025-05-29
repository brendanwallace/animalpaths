import numpy as np
import collections

from . import world
from . import animal
from . import location

RANDOM_SEED = 0


WIDTH, HEIGHT = 100, 100
DEFAULT_PATCH_RECOVERY : float = 0.0005 #* float(NUM_ANIMALS) / (STABLE_PATH_LENGTH / 0.47)
DEFAULT_PATCH_IMPROVEMENT : float = 0.05 # default 0.05


MAX_COST = 2.0

ANIMAL = animal.AStar


def random_pos():
	return np.random.rand(2)*[WIDTH, HEIGHT]

class Scenario():
	"""
	Scenarios control the following:
		- Where target locations are in space.
		- Where walkers start and end.
		- What happens when a walker reaches their target (intended location).


	This abstract class needs to be implemented.
	"""

	def __init__(
		self,
		pr=DEFAULT_PATCH_RECOVERY,
		pi=DEFAULT_PATCH_IMPROVEMENT,
		max_cost=MAX_COST
	):
		"""
		Default constructor should take all the parameters and save them, and
		construct the world. Animals + locations should be left to subclasses
		 in the 'setup' method
		"""
		np.random.seed(RANDOM_SEED)

		self.world = world.World(
			width=WIDTH,
			height=HEIGHT,
			patch_recovery=pr,
			patch_improvement=pi,
			max_cost=max_cost)
		self.updates_completed = 0

		self.patch_sums = []

		self.trip_costs = collections.deque(maxlen=500)
		self.trip_cost_average = 0.0

		self.setup()


	def setup(self):
		raise NotImplementedError


	def save_trip_cost(self, trip_cost):
		self.trip_costs.append(trip_cost)
		self.trip_cost_average = sum(self.trip_costs) / len(self.trip_costs)


	def handle_arrived(self, animal):
		# save path cost naively for now.
		# TODO - save path costs less naively
		if animal.target is not None and animal.origin is not None:
			self.save_trip_cost(animal.trip_cost)

		animal.trip_cost= 0.0

		self.new_target(animal)

	def new_target(self, animal):
		raise NotImplementedError

	def update(self):
		for a in self.animals:
			a.update()
		self.world.update()
		self.patch_sums.append(self.world.patches.sum())
		self.updates_completed += 1

	def describe(self):
		raise NotImplementedError

	def _describe(self):
		return self.describe().replace(' ', '-')


class RandomFixedLocations(Scenario):
	NUM_LOCATIONS = 10
	NUM_ANIMALS = 10

	def describe(self):
		return "random fixed locations"

	def setup(self):
		self.locations = [
			location.Location(random_pos())
			for _ in range(self.NUM_LOCATIONS)
		]
		self.animals = [
			ANIMAL(self, self.world, random_pos())
			for _ in range(self.NUM_ANIMALS)
		]


	def new_target(self, animal):
		animal.origin = animal.target
		animal.target = np.random.choice(
			# Safely exclude the location that was just our target
			[l for l in self.locations if l is not animal.target]
		)
	# def initialize_world(self):
	# 	#self.animals = [AnimalAStar(self, np.array([1, 1]))]


	# 	self.locations = locations_from_positions(self, FIXED_LOCATIONS)


	# 	animal_constructor = ANIMAL_CONSTRUCTORS[self.settings.ANIMAL]

	# 	self.animals = [animal_constructor(self, np.random.rand(2) * [self.settings.WIDTH, self.settings.HEIGHT]) for _ in range(NUM_ANIMALS)]
	# 	self.locations = self.scenario.initial_world_locations()


class RandomDynamicLocations(Scenario):
	NUM_ANIMALS = 10

	def describe(self):
		return "random dynamic locations"

	def setup(self):
		self.locations = []
		self.animals = [
			ANIMAL(self, self.world, random_pos())
			for _ in range(self.NUM_ANIMALS)
		]

	def new_target(self, a):
		if a.target is not None:
			self.locations.remove(a.target)
		a.origin = a.target
		a.target = location.Location(random_pos())
		self.locations.append(a.target)


class SharedHome(Scenario):
	NUM_ANIMALS = 10
	DELTA = 1

	def describe(self):
		return "shared home"

	def setup(self):
		self.home = location.Location(np.array([WIDTH/2.0, HEIGHT/2.0]))
		self.locations = [self.home]
		self.animals = []
		for _ in range(self.NUM_ANIMALS):
			a = ANIMAL(self, self.world, self.home.position)
			a.target = self.home
			a.handle_arrived()
			self.animals.append(a)


	def new_target(self, a):
		if a.target is self.home:

			# Remove the origin here, so that the orange dot persists.
			if a.origin is not None:
				self.locations.remove(a.origin)
			a.origin = self.home

			# Choose a random radial direction, then travel an appropriate
			# radius out.
			r = min(WIDTH, HEIGHT)/2 - self.DELTA
			theta = np.random.rand() * 2 * np.pi
			v = r * np.array([np.cos(theta), np.sin(theta)])
			a.target = location.Location(self.home.position + v)
			self.locations.append(a.target)
		else:
			a.origin = a.target
			a.target = self.home


class WallToWall(Scenario):
	NUM_ANIMALS = 10
	DELTA = 1
	def describe(self):
		return "wall to wall"

	def setup(self):
		self.locations = []
		self.animals = [
			ANIMAL(self, self.world, random_pos())
			for _ in range(self.NUM_ANIMALS)
		]

	def new_target(self, a):
		if a.target is not None:
			self.locations.remove(a.target)
		a.origin = a.target
		p = random_pos()
		if a.origin is not None and a.origin.position[0] == self.DELTA:
			p[0] = HEIGHT - self.DELTA
		else:
			p[0] = self.DELTA
		a.target = location.Location(p)
		self.locations.append(a.target)