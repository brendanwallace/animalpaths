import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation

import search

TAU = 2 * np.pi


def rotate(vector, angle):
	rotation_matrix = np.array([
		[np.cos(angle), -np.sin(angle)],
		[np.sin(angle), np.cos(angle)]])
	return rotation_matrix @ vector

def normalize(vector):
	v_norm = np.linalg.norm(vector)
	if v_norm == 0:
		return vector
	else:
		return vector / v_norm

def locations_from_positions(world, positions):
	return [Location(world, np.array(pos)) for pos in positions]

class Location():
	def __init__(self, world, position):
		self.world = world
		self.position = position


class World():
	"""
	World contains all the main organization for the simulation
	"""
	WIDTH, HEIGHT = 200, 150
	NUM_ANIMALS = 10
	#NUM_LOCATIONS = 10
	PATCH_IMPROVEMENT = 0.05
	PATCH_RECOVERY = 0.004
	MIN_COST = 1
	MAX_COST = 2

	def __init__(self):
		self.patches = np.zeros([World.WIDTH, World.HEIGHT])
		self.animals = [AnimalAStar(self) for _ in range(World.NUM_ANIMALS)]

		off = 5

		self.locations = locations_from_positions(self,
			[[off, off], [off, World.HEIGHT - off],
			[World.WIDTH - off, off], [World.WIDTH - off, World.HEIGHT - off]]
		)


	def update(self):
		for a in self.animals:
			a.update()

	def recover_patches(self):
		self.patches = self.patches - World.PATCH_RECOVERY
		# don't let patches drop below zero
		self.patches = np.max(self.patches, 0)

	def improve_patch(self, position):
		x, y = int(position[0]), int(position[1])
		# for i in [-1, 0, 1]:
		# 	for j in [-1, 0, 1]:
		# 		self.patches[x+i][y+j] += World.PATCH_IMPROVEMENT
		self.patches[x][y] += World.PATCH_IMPROVEMENT

	def cost_at(self, point):
		x, y = int(point[0]), int(point[1])

		# it's infinitely expensive to leave the world!
		if x >= World.WIDTH or y >= World.HEIGHT or x < 0 or y < 0:
			return np.inf

		# this is between 0 and 1 - 0 is maximally "comfortable", 1 is untouched
		patch_value = self.patches[x][y]
		patch_cost = patch_value * World.MAX_COST + (1 - patch_value) * World.MIN_COST
		return patch_cost


class AnimalAStar():

	def __init__(self, world):
		self.world = world
		self.position = np.random.rand(2) * [World.WIDTH, World.HEIGHT]
		self.target = None
		self.path = []


	def new_target(self):
		self.target = np.random.choice(self.world.locations)
		self.path = search.a_star(self.world, self.position, self.target.position)

	def update(self):
		# Acquire a new target randomly
		if self.target is None:
			self.new_target()


		self.move()

	def move(self):
		while len(self.path) == 0:
			self.new_target()

		self.position = self.path.pop(0)
		self.world.improve_patch(self.position)

 


class AnimalDirect():

	SPEED = 1
	DIRECTIONAL_VARIANCE = 0.01
	ARRIVED_DISTANCE = 1.0

	def __init__(self, world):
		self.world = world
		self.position = np.random.rand(2) * [World.WIDTH, World.HEIGHT]

		angle = np.random.rand() * TAU
		self.heading = np.array([np.cos(angle), np.sin(angle)])
		self.target = None

	def move(self):

		# rotate by a normally distributed angle
		angle = np.random.normal(0, Animal.DIRECTIONAL_VARIANCE) * TAU
		self.heading = rotate(self.heading, angle)

		# move
		self.position = self.position + self.heading * Animal.SPEED

		# wrap around (periodic boundary conditions)
		self.position = np.mod(self.position, [World.WIDTH, World.HEIGHT])

		# improve the patch we end up on
		self.world.improve_patch(int(self.position[0]), int(self.position[1]))

	def new_target(self):
		self.target = np.random.choice(self.world.locations)


	def update(self):
		# Acquire a new target randomly
		if self.target is None:
			self.new_target()

		# If we're there, acquire a new target
		if np.linalg.norm(self.position - self.target.position) <= Animal.ARRIVED_DISTANCE:
			self.new_target()

		self.heading = normalize(self.target.position - self.position)

		self.move()





def profile():
	w = World()
	for steps in range(1000):
		print('\r{}'.format(steps), end='')
		w.update()
		steps += 1



def main():
	w = World()
	fig = plt.figure()

	## Initializes the plots that we'll animate
	patches_imshow = plt.imshow(w.patches.T, origin="lower", vmin=0, vmax=1)
	animal_scatter = plt.scatter(
		[a.position[0] for a in w.animals],
		[a.position[1] for a in w.animals],
		s=2)
	location_scatter = plt.scatter(
		[l.position[0] for l in w.locations],
		[l.position[1] for l in w.locations], s=5)

	# prevents the scatter plots from being wider than the imshow and making
	# white space
	plt.xlim(0, World.WIDTH)
	plt.ylim(0, World.HEIGHT)


	def update(frame):
		w.update()
		patches_imshow.set_data(w.patches.T)
		animal_scatter.set_offsets(np.array([a.position for a in w.animals]))
		location_scatter.set_offsets(np.array([l.position for l in w.locations]))


	ani = animation.FuncAnimation(fig=fig, func=update, frames=100, interval=1)


	plt.show()


main()

# import cProfile
# cProfile.run("profile()")
