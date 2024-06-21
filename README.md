# Expaca

EXPeriments with Asynchronous Cellular Automata (Elixir)

There are two approaches to Cellular Automata:
- synchronous generations: all updates happen in a single global step,
  this is the usual formulation
- asynchronous evolution: updates happen according to some 
  non-deterministic but fair scheduler
  
Expaca is based on the idea of _Process Oriented Programming_ (POP):
* Algorithms are implemented using a fine-grain directed graph of 
  independent share-nothing processes.
* Processes communicate asynchronously by passing messages. 
* Process networks naturally run in parallel.

Every grid cell has its own fine grain asynchronous process,
which contains process IDs of its immediate neighbors,
so that they can exchange messages.

## 2D Grid
  
We will implement 2D rectangular grids,
but the approach could be extended to hexagonal,
or even unstructured grids.

In a 2D grid:
- integer (I,J) coordinate system
- dimension in each direction `{ni, nj}`
- total number of cells: `ncell = ni * nj`
- each cell has a location `{i, j}`
- indexes are 1-based, so `1 <= i <= ni`
  and `1 <= j <= nj`
  
Directions on a 2D grid can be described by either:
  - `{di, dj}` where values are `-1 | 0 | 1` and `{0,0}` is not allowed
  - compass direction: `:n | :ne | :e | :se | :s | :sw | : :w | :nw`
  
For Game of Life rules, we do not need detailed directional datastructures.
  
On a 2D grid there are 9 zones, where cells have a specific
topology of connections:
- NW corner (1) 3 neighbors (e, se, s)
- N edge (ni-2) 5 neighbors (e, se, s, sw, w)
- NE corner (1) 3 neighbors (s, sw, w)
- E edge (nj-2) 5 neighbors (s, sw, w, nw, n)
- SE corner (1) 3 neighbors (w, nw, n)
- S edge (ni-1) 5 neighbors (w, nw, n, ne, e)
- SW corner (1) 3 neighbors (n, ne, e)
- W edge (nj-2) 5 neighbors (n, ne, e, se, s)
- center (ni-2)*(nj-2) 8 neighbors (all directions)

There are two simple kinds of boundary conditions:
- assume zero occupancy outside the dimensions
  (clipped neighborhoods, as given above)
- cyclic boundary condition, where the boundary is the opposite edge
  (modulo arithmetic for cell locations)
  
We will initially implement zero occupancy boundary.

## Cell State

We use a simple binary state:
- `false`: empty
- `true`: occupied

## Grid State

A _frame_ is a completed step for all cells.

There are two frame representations:
- internal: set of locations that are occupied;
  empty locations are not present in the set
- external: ASCII string rendered using:
  - `'.'` empty
  - `'X'` occupied
  - `'\n'` end of row

For example, a glider:

```
  MapSet: [ {1,2}, {2,2}, {3,2}, {3,3}, {2,4} ]
```

or ASCII art version:

 ```
  \"\"\"
  .X..
  ..X.
  XXX.
  ....
  \"\"\"
  ```
  
## Update Rule

The same update rule is used for all cells (homogeneous).

There are two kinds of update rules:
- simple counts of neighboring states;
  isotropic behavior (e.g. no distinction between 
  face-adjacent and diagonal-adjacent neighbors);
  neighbors can be unordered unlabelled list
- directional rules; neighbors must be 
  labelled with directions from the cell

We will initially use the classic update rule 
from Conway's Game of Life (GoL), which uses simple counts:
- any cell with 3 occupied neighbors, stays or becomes occupied
- a live cell with 2 occupied neighbors stays alive

## Synch CA

Even though the topic of the repo is Asynch CA, 
we will begin with Synch CA.

There is still one process for every cell,
so we have to introduce synchronization mechanisms 
to execute the grid update in lockstep.

Each cell will have the following state:
- location in the grid
- collection of neighbor process addresses 
- previous state (0,1)
- generation number for previous state (1-based) 
- accumulated messages of neighboring state to calculate a new state
- some counters counting down to zero, 
  for cell update and end of simulation

The previous state is known to be complete for all cells.

The current generation is just the previous generation - 1.

There will be two types of process:
- grid manager (one instance)
  - spawns and controls the cells
  - receives updates from cells and builds result frames
  - sends completed frames to the client
  - exits after some number of generations
- cell worker (`ni*nj` instances)
  - multistage initialization of state
  - start processing
  - send state to each neighbor
  - receive state from each neighbor
  - update cell value and roll generation
  - notify manager and neighbors of completed state value
  - exit after some number of generations

## Asynch CA

Asynch CA appears to evolve at random,
but the random number generator is 
deterministic, given the original seed.
