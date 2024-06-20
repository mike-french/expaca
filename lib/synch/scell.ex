defmodule Expaca.Synch.Scell do
  @moduledoc """
  Synchronous cell.
  """

  alias Expaca, as: E

  @doc "Start the synchronous cell process."
  @spec start(E.location(), pid(), E.generation()) :: pid()
  def start(loc, grid, ngen) when is_pid(grid) do
    spawn_link(__MODULE__, :connect, [loc, grid, ngen])
  end

  # receive our neighborhood from the grid manager
  @spec connect(E.location(), pid(), E.generation()) :: no_return()
  def connect(loc, grid, ngen) do
    receive do
      {:connect, ^grid, cells} when is_list(cells) -> init(loc, grid, ngen, cells)
    end
  end

  # receive our initial state from the grid manager
  @spec init(E.location(), pid(), E.generation(), E.neighborhood()) :: no_return()
  defp init(loc, grid, ngen, cells) do
    receive do
      {:init, ^grid, state} ->
        for pid <- [grid | cells], do: send(pid, {:update, loc, state, ngen})
        scell(loc, grid, ngen, cells, state, length(cells), 0)
    end
  end

  # main loop
  # igen: generation number, count down to 0
  # csum: simple GoL update rule just needs sum of neighborhood occupancy
  # nmsg: counter for receiving messages from neighbors, count down to 0
  @spec scell(
          loc :: E.location(),
          grid :: pid(),
          igen :: E.generation(),
          cells :: E.neighborhood(),
          state :: E.state(),
          nmsg :: non_neg_integer(),
          csum :: E.occupancy()
        ) :: no_return()

  defp scell(_loc, _grid, 0, _cells, _state, _, _) do
    :ok
  end

  defp scell(loc, grid, igen, cells, state, 0, csum) do
    # received all messages from the neighborhood
    # calculate state for this generation 
    # notify grid manager and all neighbors
    new_igen = igen - 1
    new_state = update(state, csum)
    for pid <- [grid | cells], do: send(pid, {:update, loc, new_state, new_igen})
    scell(loc, grid, new_igen, cells, new_state, length(cells), 0)
  end

  defp scell(loc, grid, igen, cells, state, nmsg, csum) do
    # receive state message from neighbors for this generation
    # decrement messages to be received, increment occupancy state
    receive do
      {:update, _cloc, cval, ^igen} ->
        scell(loc, grid, igen, cells, state, nmsg - 1, csum + cval)
    end
  end

  # Game of Life update rule
  @spec update(E.state(), E.occupancy()) :: E.state()
  defp update(_, 3), do: 1
  defp update(1, 2), do: 1
  defp update(_, _), do: 0
end
