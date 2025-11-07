45 minutes: 15-25 slides

0. title slide

# Intro/motivation
1. emergent paths through positive feedback
2. urban planning – desire paths
2.5. parks. apocryphal
3. animal paths. "game trails"
4. snekdowns – higher cost environment

# Background
5. background: the helbing model
	-TODO: [ ] consider adding a second picture, removing the words
6. theoretical background - the transportaton problem. minimal vs maximal vs inbetween
7. criticism/open questions about the helbing model. costs aren't explicit. needs to land on a cost-explicit model

# Overview
7. overview of my talk
8. Path search over continuous, weighted space
	-TODO: [ ] A* search over a grid, robotics continuous space, navigational mesh
9. how the search algorithm works. implementing multiple versions

# Model
10. My model [play video demos]
	- intro
	- intro fast
	- higher cost
	- shared home
	- random-random
	- random-random fast
	- wall-to-wall
	- wall-to-wall fast
	

# Questions
11. general questions about the dynamics
	- squishy dynamics questions
	- quantify: model parameters vs costs ("transportation problem")
	- lay out a case for further studies/identify some open questions

# Results
12. dynamics of how paths form. – use the triangles here

13. shortcutting & angles; think about running along a beach and swimming out into the water. cos^-1(cost of path / cost of ground)
14. dirk helbing ratio of 1.0/1.3 => leads to 40 degree angle (two pictures)
15. high cost => closer to 90 degree angles (two pictures)

being more quantitative

17. quantify angles
	- (figure progression 1. paths, 2. heading angles in 1 path, 3. histogram)
18. show the different angle histograms


19. improvement vs recovery; damping and total amount of improvement (figure)


19. (?) model comparisons

# Methods


# Future roadmap
18. two directions. one going more theoretical, one more emperical
- consider topology
- random <-> random; does this look like a road network?
- match network to network photos -- reverse engineer energetics/behavioral preferences in people & animals
- 

(don't include the model comparison section)

