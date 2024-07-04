defmodule Expaca.Synch.Scell do
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
  @spec init(X.location(), pid(), X.generation(), X.neighborhood()) :: no_return()
  defp init(loc, grid, ngen, cells) do
    receive do
      {:init, ^grid, state} ->
        for pid <- [grid | cells], do: send(pid, {:update, loc, state, ngen})
        scell(loc, grid, ngen, cells, state, length(cells), 0)
    end
  end

  # main loop
  # igen: generation number, count down to 0
  # occ: simple GoL update rule just needs sum of neighborhood occupancy
  # nmsg: counter for receiving messages from neighbors, count down to 0
  @spec scell(
          loc :: X.location(),
          grid :: pid(),
          igen :: X.generation(),
          cells :: X.neighborhood(),
          state :: X.state(),
          nmsg :: non_neg_integer(),
          occ :: X.occupancy()
        ) :: no_return()

  defp scell(_loc, _grid, 0, _cells, _state, _, _), do: :ok

  defp scell(loc, grid, igen, cells, state, 0, occ) do
    # received all messages from the neighborhood
    # calculate state for this generation 
    # notify grid manager and all neighbors
    new_igen = igen - 1
    new_state = cell_update(occ, state)
    for pid <- [grid | cells], do: send(pid, {:update, loc, new_state, new_igen})
    scell(loc, grid, new_igen, cells, new_state, length(cells), 0)
  end

  defp scell(loc, grid, igen, cells, mystate, nmsg, occ) do
    # receive state message from neighbors for this generation
    # decrement messages to be received, increment occupancy state
    receive do
      {:update, _loc, instate, ^igen} ->
        scell(loc, grid, igen, cells, mystate, nmsg - 1, state_update(occ, instate))
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
