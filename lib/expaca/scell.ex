defmodule Expaca.Scell do
  @moduledoc """
  Synchronous cell.
  """

  alias Expaca.Types, as: X

  alias Expaca.Rules

  @doc "Start the synchronous cell process."
  @spec start(X.ijhash(), pid(), X.generation()) :: pid()
  def start(hash, grid, ngen) when is_pid(grid) do
    spawn_link(__MODULE__, :connect, [hash, grid, ngen])
  end

  # receive our neighborhood from the grid manager
  @spec connect(X.ijhash(), pid(), X.generation()) :: no_return()
  def connect(hash, grid, ngen) do
    receive do
      {:connect, ^grid, cells} when is_list(cells) -> init(hash, grid, ngen, cells)
    end
  end

  # receive our initial state from the grid manager
  # notify neighboring cells to start the simulation
  @spec init(X.ijhash(), pid(), X.generation(), X.neighborhood()) :: no_return()
  defp init(hash, grid, ngen, cells) do
    ncells = length(cells)

    receive do
      {:init, ^grid, state} ->
        msg = {:update, hash, state, 0}
        # the initial frame is also sent back to the grid
        for pid <- [grid | cells], do: send(pid, msg)
        scell(hash, grid, ngen, 0, cells, state, ncells, ncells, 0)
    end
  end

  # main loop
  @spec scell(
          # hash of location in the grid
          hash :: X.ijhash(),
          # process address of the grid manager
          grid :: pid(),
          # total number of generations to simulate
          ngen :: X.generation(),
          # generation number, count up from 0
          igen :: non_neg_integer(),
          # list of neighborhood process addresses
          cells :: X.neighborhood(),
          # boolean state: occupied (true) or empty (false)
          state :: X.state(),
          # size of the neighborhood, length(cells), no. of messages per step
          ncells :: 3..8,
          # counter for receiving messages from neighbors, count down to 0
          nmsg :: non_neg_integer(),
          # cumulative sum of neighborhood occupancy
          occ :: X.occupancy_count()
        ) :: no_return()

  defp scell(_hash, _grid, ngen, ngen, _cells, _state, _, _, _) do
    exit(:normal)
  end

  defp scell(hash, grid, ngen, igen, cells, state, ncells, 0, occ) do
    # received all messages from the neighborhood
    # calculate state for this generation, ignore change
    # notify grid manager and all neighbors
    new_igen = igen + 1
    new_state = Rules.count_update(occ, state)
    msg = {:update, hash, new_state, new_igen}
    for pid <- [grid | cells], do: send(pid, msg)
    scell(hash, grid, ngen, new_igen, cells, new_state, ncells, ncells, 0)
  end

  defp scell(hash, grid, ngen, igen, cells, state, ncells, nmsg, occ) do
    # receive state message from neighbors for this generation
    # decrement messages to be received, increment occupancy state
    receive do
      {:update, _hash, instate, ^igen} ->
        new_occ = if instate, do: occ + 1, else: occ
        scell(hash, grid, ngen, igen, cells, state, ncells, nmsg - 1, new_occ)
    end
  end
end
