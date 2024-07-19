defmodule Expaca.Acell do
  @moduledoc "Asynchronous cell."

  alias Expaca.Types, as: X

  alias Expaca.Rules

  # wait after processing local update
  # helps to achieve balanced execution
  @cell_wait 10

  @doc "Start the asynchronous cell process."
  @spec start(X.ijhash(), pid()) :: pid()
  def start(hash, grid) when is_pid(grid) do
    spawn_link(__MODULE__, :connect, [hash, grid])
  end

  # receive our neighborhood from the grid manager
  @spec connect(X.ijhash(), pid()) :: no_return()
  def connect(hash, grid) do
    receive do
      {:connect, ^grid, cells} when is_list(cells) -> init(hash, grid, cells)
    end
  end

  # receive our initial state from the grid manager
  @spec init(X.ijhash(), pid(), X.neighborhood()) :: no_return()
  defp init(hash, grid, cells) do
    # use a small hash for cell-cell messages and neighborhood map
    receive do
      {:init, ^grid, state} ->
        # notify neighboring cells 
        # the initial frame is not sent back to the grid
        msg = {:update0, hash, state}
        for pid <- cells, do: send(pid, msg)
        context(hash, grid, cells, state, length(cells), %{})
    end
  end

  # passively accumulate all the initial neighborhood occupancy states
  @spec context(
          X.ijhash(),
          pid(),
          X.neighborhood(),
          X.state(),
          non_neg_integer(),
          X.occupancy_map()
        ) :: no_return()

  defp context(hash, grid, cells, state, nmsg, hood) when nmsg > 0 do
    receive do
      {:update0, inhash, instate} ->
        new_hood = Map.put(hood, inhash, instate)
        context(hash, grid, cells, state, nmsg - 1, new_hood)
    end
  end

  defp context(hash, grid, cells, state, 0, hood) do
    acell(hash, grid, cells, state, hood)
  end

  # main loop
  # there is no fixed number of generations 
  # continue until the grid exits and shuts down the simulation
  @spec acell(
          # hash of location for use as key
          hash :: X.ijhash(),
          # process address of the grid manager
          grid :: pid(),
          # list of neighborhood process addresses
          cells :: X.neighborhood(),
          # boolean state: occupied (true) or empty (false)
          state :: X.state(),
          # map of neighborhood states
          hood :: X.occupancy_map()
        ) :: no_return()

  defp acell(hash, grid, cells, state, hood) do
    # only send an update when the local state has changed
    new_state = Rules.hood_update(hood, state)

    if new_state != state do
      msg = {:update, hash, new_state}
      for pid <- [grid | cells], do: send(pid, msg)
    end

    # pause execution to wait for neighbors to update
    Process.sleep(@cell_wait)

    # receive state change message from neighbors 
    receive do
      {:update, inhash, instate} ->
        new_hood = Map.put(hood, inhash, instate)
        acell(hash, grid, cells, new_state, new_hood)
    end
  end
end
