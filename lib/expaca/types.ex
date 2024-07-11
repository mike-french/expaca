defmodule Expaca.Types do
  @moduledoc """
  Types and guards for Expaca.
  """

  import Exa.Types
  alias Exa.Types, as: E

  alias Exa.Space.Types, as: S

  import Exa.Image.Types
  alias Exa.Image.Types, as: I

  # ---------
  # constants
  # ---------

  # maximum frame dimension
  @maxdim 256

  # maximum number of steps 
  @maxgen 1_000

  # -----
  # types
  # -----

  @typedoc "The execution mode for the cellular automaton simulation."
  @type mode() :: :synch | :asynch

  @typedoc "The state of a single cell: occupied or empty."
  @type state() :: bool()

  @typedoc "A 2D cell location as 1-based positions."
  @type location() :: S.pos2i()

  # TODO - push this into Exa Image?
  @typedoc "Dimensions of the grid: width, height."
  @type dimensions() :: {I.size(), I.size()}

  defguard is_dims(w, h)
           when is_size(w) and 3 <= w and w <= @maxdim and
                  is_size(h) and 3 <= h and h <= @maxdim

  @typedoc "The number of occupied neighbors for cell."
  @type occupancy_count() :: 0..8

  @typedoc "Map of neighborhood occupancy."
  @type occupancy_map() :: %{location() => state()}

  @typedoc """
  A frame in the simulation.
  The set contains occupied locations.
  """
  @type frame() :: {I.size(), I.size(), MapSet.t()}

  defguard is_frame(f)
           when is_fix_tuple(f, 3) and
                  is_dims(elem(f, 0), elem(f, 1)) and is_struct(elem(f, 2), MapSet)

  @typedoc "A frame represented as an ascii art string."
  @type asciiart() :: {I.size(), I.size(), String.t()}

  # allow for Windows or Unix line endings
  defguard is_asciiart(f)
           when is_fix_tuple(f, 3) and
                  is_dims(elem(f, 0), elem(f, 1)) and is_string(elem(f, 2)) and
                  (byte_size(elem(f, 2)) == elem(f, 1) * (elem(f, 0) + 1) or
                     byte_size(elem(f, 2)) == elem(f, 1) * (elem(f, 0) + 2))

  @typedoc "The number of generations"
  @type generation() :: E.count1()

  defguard is_ngen(n) when is_count1(n) and n <= @maxgen

  @typedoc """
  An active implementation grid is a 
  map of locations to processes.
  """
  @type grid() :: %{location() => pid()}

  @typedoc "Simple neighborhood is just a list of 3-8 adjacent processes."
  @type neighborhood() :: [pid(), ...]
end
