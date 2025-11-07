----
title: Paper outline
date: November 1, 2024
updated: May 13, 2025
----


# Emergent Transportation Networks

## Intro

Emergent paths form through positive feedback

1. Human paths. called "desire paths"
	- desire paths, infrastructure doesn't match needs
	- snekdowns
	- MSU path

2. Ecologists (also hunters) call these "game trails"
	- don't have a ton of slides for this but could.

3. Collective algorithm to solve "the transportation problem"
	- fully connected (low cost environment)
	- high cost (snow)
	- basically, how good is this algorithm (while true: take the cheapest path)

Helbing model, following the gradient

Introduce the model

## Results

### I. Dynamics, stability, topology, obstacles. Describe
_How do trails form?_
_What shape do trails take?_
_How stable are they?_


Trails form through:
- new paths (starts with direct), zipping & unzipping
- shortcuts
	* critical angle of departure; function of cost. influences angles of the network.
- dragging
	* if a path segment can't be "shortcutted", it can still be moved, over time, through the process of a walker favoring one side of the segment.
- obstacles
	* obstacles can prevent paths from being dragged. so if a path is stable under shortcutting, obstacles can hold them stable
	* this explains why paths tend to touch obstacles

pR vs pI controls how much trail can form//how minimal the network is. more vs less damped.
below a threshold, no path forms.
then, minimal networks.
then, at a certain point, no deviation from direct paths.
=> can think about laying down path vs path erosion and solve for an amount of length

shortcutting angle determined by cost ratio. controls angles in the network.
cos^-1(cost_path/cost_ground)



[a couple diagram-y pictures]



### II. pR, pI, maxCost. The Transportation Problem. Quantify

[Pareto curve plot]
(pR, pI, maxCost) vs total improvement vs path costs

(diffusion variance of 1 looks best)

-TODO: look at logistic patch recovery to make costs more comparable, and avoid the runaway improvement problem with high pR
-TODO: save snapshots using HDF5

[max cost vs topology curve]

--TODO: implement angles-of-turns--
TODO: implement heading-vs-final distributions

conclusions:
- networks bound by a smooth pareto curve (obviously); seems to mostly improve; evolution defined by periods stagnation and periods of innovation
- more "budget" -> more infrastructure, cheaper cost
- more "damping" -> network emerges more slowly, but closer to the pareto front
- [guessing this] higher cost <-> less path allocated -> prefer less infrastructure//innovation is slower


### III. Internal Geometry vs Cost

#### 1. Angle should depend on cost. (figure A)

#### 2. How we measure angles in the network (figure B)

#### 3. Explain results (figure C)



## Other Stuff

### IV. Other Scenarios, including Random <-> Random Fractals

### V. Model Comparison. Compare

descriptive breakdown of the differences here

[Pareto curve plot of all the different models]






## Methods
