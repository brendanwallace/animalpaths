----
title: Trail model parameters
date: May 5, 2025
----

## Key parameters

### trail improvement & trail decay

the ratio of these parameters controls how much trail length is available to the walkers

single value: [75]? or [50]?
core values to consider: [100, 75, 50]
maybe consider: [200, 25]

there's a sweet spot where interesting things can happen. too high and the walkers make a fully-connected straight-line network. too low and they don't build any network.

fixing the ratio, trail decay controls how jittery or smooth the path development is. when trail development is jittery, the walkers are less able to build a precise network and efficiency can suffer. but on the flip side, when things are jittery, the walkers sometimes "discover" "innovations" in the network that are harder to find when the regime is smooth.

single value: [0.0002]
core values to consider: [0.002, 0.0002]
consider a wider range for some fixed values of other parameters





- __ground:trail cost ratio__


core: [2, 8]
consider: [2, 4, 8, 16]

explore the relationship between this and angles in the network. will probably need to fix everything else and do this.

### ground/trail cost

### trail creation/decay logic

- trail improvement logic. [logistic, linear, saturating]

## ?? parameters

### boundary condition

- [solid & periodic]

### scenario (we mostly consider fixed random & dynamic random)

core for analysis: [fixed random]
also core, but for a later paper: [dynamic random]
more tangential: [all the other ones]

- number of POIs (for fixed random)

not sure what effect this has, or how it interfaces with boundary conditions

consider 10 vs 15 vs 20


- starting position of fixed random positions

randomly chosen, but should explore at least 10 of these; if not more.

consider 10, with 100 random runs

- 

## comparison parameter

### search strategy (compare the different ones, but Kanai-Suzuki is the focus)



## Size parameters

### size of world (usually 100x100)
### number of walkers
### diffusion gaussian variance


## Implementation details
- search strategy number of steiner points
- diffusion radius
