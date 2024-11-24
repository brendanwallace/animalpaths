# Abstract:

## Describes the larger problem

When a person or animal walks through rough terrain, they flatten the ground and make it easier to walk along the same path they took. This positive feedback can lead to a well-formed trail or, when multiple walkers travel between multiple destinations, an entire emergent trail network.


## History/background

Dirk Helbing showed, with his simple active-walker model in which ground is made more "comfortable", and in which walkers are drawn towards their target destination _and_ towards the gradient of increasing ground comfort, that simple behavior can recreate qualitative properties observed in pedestrian trail networks.

## What we did

Here, we present an alternative _cost-explicit_ active walker model. In our model "cost" of traversing ground is improved (rather than attractive comfort), and walkers walk a _least-cost path_ to their target.

## Results 

We show how an algorithm for shortest paths along a polyhedral surface can be adapted to efficiently find any-directional least-cost paths through a 2-D grid of costs.

We show that explicit costs allows us to frame trail networks as "solutions" to the dual-optimization "transportation problem," and find that over a wide range of parameters active-walkers are able to construct pareto-efficient solutions.

We propose a simple mechanism for why trail networks in inherently high-cost environments form more minimally, with paths meeting at higher angles, and demonstrate this effect in our model.

We use these quantitative frameworks to compare our _cost-explicit_ model to the original ground-comfort model, as well as other simple variants.

Finally, we explore a range of situations, ranging from realistic to abstract, by simulating them with our model, and qualitatively discussing the network properties we observe as well as possible applications and implications.

[note: "situations"? "scenarios"? "arrangements of targets/destinations"? I'm not sure how to succinctly describe this]