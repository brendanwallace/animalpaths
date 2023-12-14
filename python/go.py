import ctypes
import array
import json
import math 

library = ctypes.cdll.LoadLibrary('./library.so')

Search = library.Search
Search.argtypes = [
	ctypes.c_void_p,
	ctypes.c_int, ctypes.c_int,
	ctypes.c_double, ctypes.c_double, ctypes.c_double, ctypes.c_double, 
]
Search.restype = ctypes.c_void_p

Free = library.Free
Free.argtypes = [
	ctypes.c_void_p
]


world_raw = [
	1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 1.0,
]
x = 4
y = 4
start_x, start_y = 0, 0,
end_x, end_y = 2.0, 2.0

world_array = (ctypes.c_float * len(world_raw))(*world_raw)

print(	(ctypes.c_float)(end_x))



path_ptr = Search(
	world_array, x, y,
	0.0, 0.0,
	2.0, 2.0,
)



path_bytes = ctypes.string_at(path_ptr)
print(path_bytes)


data = json.loads(path_bytes)
# print(data)
# print(data['Path'])
for entry in data['Path']:
	print(entry['X'], entry['Y'])


print("path_ptr:", path_ptr)
Free(path_ptr)


# print("path_ptr:", path_ptr)



# library.Free.argtype = [ctypes.c_void_p]
# library.Free(path_ptr)
