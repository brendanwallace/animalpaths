import pytest

from . import scenario

def test_random_fixed_locations_sanity():
	s = scenario.RandomFixedLocations()
	s.update()


