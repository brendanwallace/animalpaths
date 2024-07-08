import ctypes
import array
import json
import math
import numpy as np

library = ctypes.cdll.LoadLibrary('./library.so')

Search = library.Search
Search.argtypes = [
	# worldPtr *float64
	ctypes.c_void_p,
	# x, y int
	ctypes.c_int, ctypes.c_int,
	# startX, startY, endX, endY
	ctypes.c_double, ctypes.c_double, ctypes.c_double, ctypes.c_double, 
	# RADIAL_INCREMENTS, STEP_SIZE, FOUND_RADIUS, MIN_COST, PRECISION, PESSIMISM
	ctypes.c_int, ctypes.c_double, ctypes.c_double, ctypes.c_double, ctypes.c_double, ctypes.c_double, 

]
Search.restype = ctypes.c_void_p

Free = library.Free
Free.argtypes = [
	ctypes.c_void_p
]

def a_star(world, start, target,
	radial_increments, step_size, found_radius, min_cost, precision, pessimism):
	"""
	Inbetween method that calls the go library and handles parsing the response
	out of json.
	"""
	world_raw, height, width = world.raw_costs()


	[start_x, start_y] = start
	[end_x, end_y] = target

	world_array = (ctypes.c_double * len(world_raw))(*world_raw)


	path_ptr = Search(
		world_array, height, width,
		start_x, start_y,
		end_x, end_y,
		radial_increments, step_size, found_radius, min_cost, precision, pessimism
	)



	path_bytes = ctypes.string_at(path_ptr)
	# print("path bytes")
	# print(path_bytes)


	data = json.loads(path_bytes)
	Free(path_ptr)

	# print(data)
	# print(data['Path'])
	path = []
	for entry in data['Path']:
		path.append(np.array([entry['X'], entry['Y']]))


	return path



