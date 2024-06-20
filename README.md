# Expaca

EXPeriments with Asynchronous Cellular Automata (Elixir)

There are two approaches to Cellular Automata:
- synchronous generations: all updates happen in a single global step
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
- integer I,J coordinate system
- dimension in each direction `{ni, nj}`
- total number of cells: `ncell = ni * nj`
- each cell has a location `{i, j}`
- indexes are 1-based, so `1 <= i <= ni`
  and `1 <= j <= nj`
  
Directions on a 2D grid can be described by either:
  - `{di, dj}` where values are `-1 | 0 | 1` and `{0,0}` is not allowed
  - compass direction: `:n | :ne | :e | :se | :s | :sw | : :w | :nw`
  
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

## Cell State

We will use a simple binary state:
- 0, false, empty, white
- 1, true, occupied, black
  
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
....

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
- current state (0,1)
- generation number for previous state (1-based) 

The previous state is known to be complete for all cells.

The current generation is just the previous generation + 1.

There will be two types of process:
- grid manager (one instance)
  - spawns and controls the cells
  - receives output for rendering (TODO)
  - exits and shuts down cells after some number of generations
- cell worker (`ni*nj` instances)
  - multistage initialization of state
  - start processing
  - send state to each neighbor
  - receive state from each neighbor
  - update cell value and roll generation
  - notify manager of completed step
  - wait until the shutdown message is repeat:
   

The basic sequence of execution for the grid manager will be:
- create a grid manager process:
  - grid spawns and control the cells
  - receive output for rendering (TODO)
  - send shutdown after some fixed number of generations
- grid manager creates all process cells in the grid
  - initialize state for generation, cell value, manager address
- grid manager sends topology messages to all cells
  containing collection of neighbor addresses 
- grid sends initial cell values and cells start evolution




## Asynch CA

Asynch CA appears to evolve at random,
but the random number generator is 
deterministic, given the original seed.
