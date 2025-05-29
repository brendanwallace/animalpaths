





class Settings():
	# World/Simulation Parameters
	WIDTH, HEIGHT = 100, 100
	MIN_COST = 1.0
	MAX_COST = 2.0

	NUM_ANIMALS : int = 10
	ANIMAL_SPEED : float = 1.0
	MAX_PATCH_VALUE : float = 1.0
	#NUM_LOCATIONS = 10
	PATCH_IMPROVEMENT : float = 0.05
	STABLE_PATH_LENGTH = 550
	PATCH_RECOVERY : float = PATCH_IMPROVEMENT * float(NUM_ANIMALS) / (STABLE_PATH_LENGTH / 0.47)
	DIFFUSION_RADIUS : int = 3
	DIFFUSION_GAUSSIAN_VARIANCE : float = 10.0

	# Animal Behavior
	# Set to "ASTAR" or "GRADIENT" or "DIRECT"
	ANIMAL = "ASTAR" #animal.AStar

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




# OFFSET = 5
# SQUARE = [[OFFSET, OFFSET], [OFFSET, HEIGHT - OFFSET],
# 			[WIDTH - OFFSET, OFFSET], [WIDTH - OFFSET, HEIGHT - OFFSET]]

# TRIANGLE = [
# 	[OFFSET, OFFSET + 10],
# 	[WIDTH - OFFSET, OFFSET + 10],
# 	[WIDTH/2, int((WIDTH - 2*OFFSET)*np.sqrt(3)/2)+OFFSET + 10],
# ]

# FIXED_LOCATIONS = SQUARE