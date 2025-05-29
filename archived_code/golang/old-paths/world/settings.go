package world

import "math"

const MAX_COST = 2.0
const MIN_COST = 1.0
const FLATTEN_RADIUS = 2
const WIDTH = 200
const HEIGHT = 200
const ALL_RANDOM = false
const TORUS = false
const NEIGHBOR_FLATTEN = 1.0
const FLATTEN_COEFFICIENT = 0.01
const RECOVERY_COEFFICIENT = 0.001
const ANIMALS = 1
const POINTS_OF_INTEREST = 1

const ANIMAL_SPEED = 1.0

// SEARCH_RADIUS is the length of segments an animal considers when
// deciding the preferred direction to head.
const SEARCH_RADIUS = 1.0

const TURN_INTERVAL = math.Pi / 720

const HOME_PERCENTAGE = 0.0

// ARRIVED_DISTANCE determines whether an animal has gotten to its point of interest
const ARRIVED_DISTANCE = ANIMAL_SPEED * 2.0

// Search options
const HEURISTIC_OPTION = "heuristic option"
const AVERAGE_OPTION = "average option"
const GRADIENT_OPTION = "gradient options"
const SEARCH_STRATEGY = GRADIENT_OPTION

// POINTS OF INTEREST SETUP
const POI_RANDOM = "POI_RANDOM"
const POI_SET = "POI_SET"
const POINTS_OF_INTEREST_MODE = POI_SET
