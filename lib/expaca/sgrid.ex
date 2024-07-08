defmodule Expaca.Sgrid do
  @moduledoc """
  Synchronous grid implemented as a 
  connected set of asynchronous processes.
  """
  require Logger

  alias Expaca.Types, as: X

  alias Expaca.Scell
  alias Expaca.Frame
  alias Expaca.Rules

  @doc "Start the synchronous grid process."
  @spec start(X.frame(), X.generation(), nil | pid()) :: pid()
  def start(frame0, ngen, client) do
    client =
      cond do
        is_nil(client) -> self()
        is_pid(client) -> client
      end

    spawn_link(__MODULE__, :init, [frame0, ngen, client])
  end

  @spec init(X.frame(), X.generation(), pid()) :: no_return()
  def init({ni, nj, fset0}, ngen, client) do
    self = self()
    dims = {ni, nj}

    # initialize the grid, start all cells
    grid =
      for j <- 1..nj, i <- 1..ni, loc = {i, j}, into: %{} do
        {loc, Scell.start(loc, self(), ngen)}
      end

    # send the cells their neighborhood connections
    for {loc, pid} <- grid do
      cells = Rules.neighborhood(loc, dims, grid)
      send(pid, {:connect, self, cells})
    end

    # send the initial state and start evolving
    for j <- 1..nj, i <- 1..ni, loc = {i, j} do
      send(Map.fetch!(grid, loc), {:init, self, MapSet.member?(fset0, loc)})
    end

    sgrid(client, dims, grid, ngen, 0, map_size(grid), MapSet.new())
  end

  # main loop
  @spec sgrid(
          client :: pid(),
          dims :: X.dimensions(),
          grid :: X.grid(),
          ngen :: X.generation(),
          igen :: non_neg_integer(),
          nmsg :: non_neg_integer(),
          fset :: MapSet.t()
        ) :: no_return()

  def sgrid(client, _dims, _grid, ngen, ngen, _nmsg, _fset) do
    # end of all generations
    send(client, :end_of_frames)
  end

  def sgrid(client, {w, h} = dims, grid, ngen, igen, 0, fset) do
    # end of frame for this generation 
    # report to client, inrement generation and initialize next frame
    Logger.info("sgrid frame #{igen}")
    send(client, {:frame, igen, Frame.to_bitmap({w, h, fset})})
    :erlang.garbage_collect()
    sgrid(client, dims, grid, ngen, igen + 1, map_size(grid), MapSet.new())
  end

  def sgrid(client, dims, grid, ngen, igen, nmsg, fset) do
    # accumulate a frame from all cell updates
    receive do
      {:update, loc, state, ^igen} ->
        new_fset = if state, do: MapSet.put(fset, loc), else: fset
        sgrid(client, dims, grid, ngen, igen, nmsg - 1, new_fset)
    end
  end
end
