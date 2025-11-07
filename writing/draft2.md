---
title: Trails 2nd draft
geometry: margin=2cm
# mainfont: "Times New Roman"
# fontsize: 12pt
header-includes:
  - \usepackage{setspace}
  - \doublespacing # or \onehalfspacing
---

<!---
NEXT STEPS:

- use the first draft from overleaf and draft in some text in here

- keep working on figures & figure captions

--->

## 0. abstract

Stepping off a sidewalk to cut through the grass leaves an indentation, making it easier to walk the same way.
Over time, positive feedback can form a trail; sometimes called a desire path, an elephant path; or in ecology a game trail.
These trails can form entire networks, as in the case of Michigan State University, where walking paths were allowed to form organically in the lawn before being paved (figure 1); or in the case of bear trails observed in Alaska (figure 1). Across domains, these trails share a distinct organic shape; they connect destinations not with straight lines, but with paths that merge and split and loop.

Here we explore the dynamics of such networks using a simple active-walker model. Agents move between points of interest in a continuous 2-dimensional space, creating low-cost "trail" where they move, and taking the least-cost path to their destination.
We find that such a process creates highly intricate networks across a range of scenarios.
When presented with different rates of trail formation and decay, walkers produce appropriately minimal network that minimize travel costs for a given sustainable amount of trail. 
We show a simple relationship between the relative cost of traveling off the path and the angles at which trails meet in the network, and investigate the dynamics of the process.

## 1. MSU story

After expanding their campus in the 1960s, Michigan State University (Lancing, USA), didn't pave sidewalks between the new buildings. They let students walk on the grass between the buildings and slowly wear down their own paths before paving the trails that formed. The students formed trails that don't connect buildings in straight lines; they merge, split, and take on a distinct organic shape that can be seen across domains where people or animals form trail networks through the same positive-feedback process.

## 2. Theoretical background

<!-- 

- 1. "active-walker model"
- 2. euclidean steiner problem
- 3. how well does collective behavior solve this? -->

It's not known how efficient these networks are, how stable they are over time, or generally known what minimal set of conditions are necessary for this process to occur.

A related concept is the "euclidean steiner problem" of connecting a set of points drawing a minimal length of path. This is known to be NP-hard, but is solved in nature by slime mold. What are the abilities of a simple, uncoordinated collective behavior in solving this problem?


An "active-walker" model can produce realistic appearing tableaus of trail, as well as simple trail networks spanning 3 or 4 points of interest. However, such a model doesn't allow for travel costs to be quantified explicitly, nor does it appear to produce detailed trail networks spanning greater numbers of points.


## 3. Model introduction & qualitative results

We investigate the dynamics of this process using a simple computational model, in which we make travel costs explicit and quantifiable. Agents move between points of interest, decreasing the _cost_ of small patches of ground where they move, and following the least-cost paths as computed by an iterative polyhedral search algorithm.


As agents move, they slowly form a network of trail. The network appears fixed, but over time continues to shift, taking on a distinct organic shape. We vary a small number of model parameters to investigate how this affects the shape, efficiency, and dynamics of the networks.

(figure 3 -- basic explainer)

<!-- does this go here? -->

Finally, when we vary the logic of how points are arranged, and where walkers visit, we first recreate some findings of the active-walker model and then discover novel fractal-like shapes in the networks.

## 4. Efficiency

We quantify the "efficiency" of a network by measuring the pairwise cost of travel between all points _T_, and the total amount of trail improvement _I_.
Formally, this is known as the dual-optimization "transportation problem".

[reference transportation problem and dual-optimization pareto-efficiency]

Given the greedy nature of the collective algorithm at play here, we may not expect much deviation or structure to the results here.

On the contrary, we find that solutions fall neatly along a Pareto-efficient curve, such that _T_ costs can't be decreased without increasing _I_, and vice versa, suggesting that walkers efficiently adapt to the presented trail budget and make the correct tradeoff between length of trail and overall travel costs. (figure 5 -- efficiency)

## 4.5 Improvement over time

When measured over time for a single network, we find that _T_ increase and _I_ decrease in an S-shaped curve. Initial improvement is slow, but opportunities for collaboration accelerate and there's positive feedback.
Additionally, this process is not always smooth, it features stochastic jumps of "innovation" and hysteresis.

## 5. Geometry

We quantify the geometry of the network by defining _angle of deviation_ along a path. 

[should we also hand-measure some of the angles?]

We expect, based on the pool-lifeguard thing, a specific relationship between these angles in the network and the cost of deviating from the trail; and we find a destinctly linear relationship.

Snow thing close to 90 degrees –– implies extremely high cost of deviating. Additionally, Helbing quoted as saying 1.3 deviation. Equation [above] suggests angles of deviation around 40 degrees; and this is about what we see in the picture.

(figure 6 -- geometry)


## 6. Stability & replicability

To explore the dynamics of this process, i.e. does the same network form every time? how stable are the final "solutions"? we run many replicas using the same configuration of points and model parameters but different starting positions of walkers, and use PCA to visualize networks over time as trajectories through lower-dimensional phase-space (figure 7 -- dynamics)

We find that some configurations have multiple stable solutions, and some only one. We found this to be true even with very smooth model parameters.

## 7. Previous models

In contrast to the original active-walker model, we make costs explicit and ...

[not sure what to say for this part]

## 8. Need for additional work

In light of new work on animal trail networks and anticipated availability of more such data, we hope that additional work into the basic theory of how such emergent transportation networks will help us understand animal energetics and behavior.

We should explore the dynamics further; this is a cool math problem. When points are not fixed (or in the limit of $N \to \infty$ points), we additionally find novel fractal-like shapes that bear resemblance to city road networks. City networks may share this basic structure, so understanding its dynamics and efficiency is warranted.


