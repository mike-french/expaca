defmodule Expaca.Scell do
  @moduledoc """
  Synchronous cell.
  """

  alias Expaca.Types, as: X

  @doc "Start the synchronous cell process."
  @spec start(X.location(), pid(), X.generation()) :: pid()
  def start(loc, grid, ngen) when is_pid(grid) do
    spawn_link(__MODULE__, :connect, [loc, grid, ngen])
  end

  # receive our neighborhood from the grid manager
  @spec connect(X.location(), pid(), X.generation()) :: no_return()
  def connect(loc, grid, ngen) do
    receive do
      {:connect, ^grid, cells} when is_list(cells) -> init(loc, grid, ngen, cells)
    end
  end

  # receive our initial state from the grid manager
  # note that the initial frame is sent back to the grid
  @spec init(X.location(), pid(), X.generation(), X.neighborhood()) :: no_return()
  defp init(loc, grid, ngen, cells) do
    ncells = length(cells)

    receive do
      {:init, ^grid, state} ->
        msg = {:update, loc, state, 0}
        for pid <- [grid | cells], do: send(pid, msg)
        scell(loc, grid, ngen, 0, cells, state, ncells, ncells, 0)
    end
  end

  # main loop
  # ngen: target number of generations
  # igen: generation number, count up from 0
  # ncells: length(cells) the number of messages for each update
  # nmsg: counter for receiving messages from neighbors, count down to 0
  # occ: simple GoL update rule just needs sum of neighborhood occupancy
  @spec scell(
          loc :: X.location(),
          grid :: pid(),
          ngen :: X.generation(),
          igen :: non_neg_integer(),
          cells :: X.neighborhood(),
          state :: X.state(),
          ncells :: 3..8,
          nmsg :: non_neg_integer(),
          occ :: X.occupancy()
        ) :: no_return()

  defp scell(_loc, _grid, ngen, ngen, _cells, _state, _, _, _), do: :ok

  defp scell(loc, grid, ngen, igen, cells, state, ncells, 0, occ) do
    # received all messages from the neighborhood
    # calculate state for this generation 
    # notify grid manager and all neighbors
    new_igen = igen + 1
    new_state = cell_update(occ, state)
    msg = {:update, loc, new_state, new_igen}
    for pid <- [grid | cells], do: send(pid, msg)
    scell(loc, grid, ngen, new_igen, cells, new_state, ncells, ncells, 0)
  end

  defp scell(loc, grid, ngen, igen, cells, mystate, ncells, nmsg, occ) do
    # receive state message from neighbors for this generation
    # decrement messages to be received, increment occupancy state
    receive do
      {:update, _loc, instate, ^igen} ->
        new_state = state_update(occ, instate)
        scell(loc, grid, ngen, igen, cells, mystate, ncells, nmsg - 1, new_state)
    end
  end

  # Game of Life update rule
  @spec cell_update(X.occupancy(), X.state()) :: X.state()
  defp cell_update(3, _any), do: true
  defp cell_update(2, true), do: true
  defp cell_update(_, _any), do: false

  # update occupancy of neighborhood
  @spec state_update(X.occupancy(), X.state()) :: X.occupancy()
  defp state_update(occ, false), do: occ
  defp state_update(occ, true), do: occ + 1
end
