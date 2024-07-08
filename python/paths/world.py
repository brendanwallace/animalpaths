import numpy as np
import math 

from . import util

TAU : float = 2 * np.pi

MIN_COST = 1.0

MAX_PATCH_VALUE : float = 1.0
DIFFUSION_RADIUS : int = 3
DIFFUSION_GAUSSIAN_VARIANCE : float = 2.0



class World():
	"""
	World contains and manages the grid on which animals walk; and the related
	cost conversions.

	May also contain terrain features such as obstacles (e.g. a lake) and
	pinch points (e.g. as through a pass).
	"""

	def describe(self):
		return f'cost:{self.max_cost}, r:{self.patch_recovery}, i:{self.patch_improvement}'

	def _describe(self):
		return self.describe().replace(' ', '')

	def __init__(self, width, height, patch_recovery, patch_improvement, max_cost):

		# TODO - allow for loading of these via some text/file format.
		# TODO - this may need more flexibility for the scenario to manually
		# manage, so that we can do obstacles, etc.

		self.width = width
		self.height = height
		self.patches = np.zeros([height, width])
		self.patch_recovery = patch_recovery
		self.patch_improvement = patch_improvement
		self.max_cost = max_cost




	def update(self):
		self.recover_patches()

	def recover_patches(self):
		self.patches -= self.patch_recovery #* (self.patches)
		# don't let patches drop below zero
		self.patches = np.clip(self.patches, 0, 1)

	def _improve(self, x, y, improvement):
		before = self.patches[y][x]
		self.patches[y][x] += improvement
		self.patches[y][x] = min(self.patches[y][x], MAX_PATCH_VALUE)

		# self.added += self.patches[y][x] - before

	def improve_patch(self, position):
		"""
		Uses radial gaussian blur
		"""
		# "radius" of the box we consider improving
		r = DIFFUSION_RADIUS
		x, y = int(position[0]), int(position[1])

		total_improved = 0.0
		for dx in range(-r, r+1):
			for dy in range(-r, r+1):

				_x, _y = x+dx, y+dy
				improvement_value = gaussian_diffusion(self.patch_improvement, DIFFUSION_GAUSSIAN_VARIANCE, dx, dy)
				total_improved += improvement_value


				if _x >= 0 and _x < self.width and _y >= 0 and _y < self.height:
					self._improve(_x, _y, improvement_value)

		#print(f"total improved: {total_improved}. normalized: {total_improved/math.sqrt(TAU * DIFFUSION_GAUSSIAN_VARIANCE)}")

	def cost_at(self, point):
		x, y = int(point[0]), int(point[1])

		# it's infinitely expensive to leave the world!
		if x >= self.width or y >= self.height or x < 0 or y < 0:
			return np.inf

		# this is between 0 and 1 - 1 is maximally "comfortable", 0 is untouched
		patch_value = min(1.0, self.patches[x][y])
		patch_cost = patch_value * MIN_COST + (1 - patch_value) * self.max_cost
		return patch_cost

	def cost_between(self, a, b):
		return (self.cost_at(a) + self.cost_at(b)) / 2.0 * util.distance_between(a, b)


	def comfort_at(self, point):
		"""
		Returns the comfort at `point`.

		This method is boundary safe.
		"""
		x, y = int(point[0]), int(point[1])

		# it's not comfortable to leave the  but don't use infinities here
		if x >= self.width or y >= self.height or x < 0 or y < 0:
			return 0.0

		# this is between 0 and 1 - 1 is maximally "comfortable", 0 is untouched
		patch_value = min(self.patches[x][y], 1.0)
		return patch_value



	def raw_costs(self) -> (list[float], int, int):
		clipped_patches = np.clip(self.patches, 0.0, 1.0)
		costs = clipped_patches * MIN_COST + (1.0 - clipped_patches) * self.max_cost
		# print("returning costs: ", costs)
		return costs.flatten().tolist(), self.height, self.width



def locations_from_positions(world, positions):
	return [Location(world, np.array(pos)) for pos in positions]


def gaussian_diffusion(base_patch_improvement, variance, dx, dy):
	
	normalization = 1.0 / math.sqrt(TAU * variance)
	density = math.exp(-0.5 * (dx**2 + dy**2)/ variance)
	return base_patch_improvement * normalization * density





