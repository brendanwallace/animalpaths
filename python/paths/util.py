import numpy as np

TAU : float = np.pi * 2



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


def distance_between(p1, p2):
	return np.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)
	#return np.linalg.norm(p1 - p2)


def test_distance_between():
	np.testing.assert_almost_equal(
		## 3, 4, 5 triangle
		distance_between(np.array([0, 0]), np.array([3, 4])), 5.0)