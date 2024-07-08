defmodule Expaca.Acell do
  @moduledoc "Asynchronous cell."

  alias Expaca.Types, as: X

  alias Expaca.Rules

  @doc "Start the asynchronous cell process."
  @spec start(X.location(), pid()) :: pid()
  def start(loc, grid) when is_pid(grid) do
    spawn_link(__MODULE__, :connect, [loc, grid])
  end

  # receive our neighborhood from the grid manager
  @spec connect(X.location(), pid()) :: no_return()
  def connect(loc, grid) do
    receive do
      {:connect, ^grid, cells} when is_list(cells) -> init(loc, grid, cells)
    end
  end

  # receive our initial state from the grid manager
  @spec init(X.location(), pid(), X.neighborhood()) :: no_return()
  defp init(loc, grid, cells) do
    receive do
      {:init, ^grid, state} ->
        msg = {:update0, loc, state}
        # notify neighboring cells 
        # the initial frame is not sent back to the grid
        for pid <- cells, do: send(pid, msg)
        context(loc, grid, cells, state, length(cells), %{})
    end
  end

  # passively accumulate all the initial neighborhood occupancy states
  @spec context(
          X.location(),
          pid(),
          X.neighborhood(),
          X.state(),
          non_neg_integer(),
          X.occupancy_map()
        ) :: no_return()

  defp context(loc, grid, cells, state, 0, hood) do
    acell(loc, grid, cells, state, hood)
  end

  defp context(loc, grid, cells, state, nmsg, hood) do
    receive do
      {:update0, inloc, instate} ->
        new_hood = Map.put(hood, inloc, instate)
        context(loc, grid, cells, state, nmsg - 1, new_hood)
    end
  end

  # main loop
  # there really is no fixed number of generations here
  # acell continues until the grid exits and shuts down the simulation
  @spec acell(
          # location in the grid
          loc :: X.location(),
          # process address of the grid manager
          grid :: pid(),
          # list of neighborhood process addresses
          cells :: X.neighborhood(),
          # boolean state: occupied (true) or empty (false)
          state :: X.state(),
          # map of neighborhood states
          hood :: X.occupancy_map()
        ) :: no_return()

  defp acell(loc, grid, cells, state, hood) do
    # receive state change message from neighbors 
    receive do
      {:update, inloc, instate} ->
        new_hood = Map.put(hood, inloc, instate)
        new_state = new_hood |> occupancy() |> Rules.cell_update(state)
        # only send an update when the local state has changed
        if new_state != state do
          msg = {:update, loc, new_state}
          for pid <- [grid | cells], do: send(pid, msg)
        end

        acell(loc, grid, cells, new_state, new_hood)
    end
  end

  @spec occupancy(X.occupancy_map()) :: X.occupancy_count()
  defp occupancy(hood) do
    Enum.reduce(hood, 0, fn
      {_pid, false}, occ -> occ
      {_pid, true}, occ -> occ + 1
    end)
  end
end
