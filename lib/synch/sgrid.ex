defmodule Expaca.Synch.Sgrid do
  @moduledoc """
  Synchronous grid implemented as a 
  connected set of asynchronous processes.
  """
  require Logger
  alias Expaca.Types, as: X
  alias Expaca.Synch.Scell

  @doc "Start the synchronous grid process."
  @spec start(X.frame(), X.generation()) :: pid()
  def start({w, h, frame0}, ngen) do
    spawn_link(__MODULE__, :init, [self(), {w, h}, ngen, frame0])
  end

  @spec init(pid(), X.dimensions(), X.generation(), MapSet.t()) :: no_return()
  def init(client, {ni, nj} = dims, ngen, frame0) do
    # initialize the grid, start all cells
    grid =
      for j <- 1..nj, i <- 1..ni, loc = {i, j}, into: %{} do
        {loc, Scell.start(loc, self(), ngen)}
      end

    # send the cells their neighborhood connections
    for {loc, pid} <- grid do
      send(pid, {:connect, self(), neighborhood(loc, dims, grid)})
    end

    # send the initial state and trigger them to start evolving
    for j <- 1..nj, i <- 1..ni, loc = {i, j} do
      send(Map.fetch!(grid, loc), {:init, self(), MapSet.member?(frame0, loc)})
    end

    sgrid(client, dims, grid, ngen, map_size(grid), MapSet.new())
  end

  # main loop
  @spec sgrid(
          client :: pid(),
          dims :: X.dimensions(),
          grid :: X.grid(),
          igen :: X.generation(),
          nmsg :: non_neg_integer(),
          frame :: MapSet.t()
        ) :: no_return()

  def sgrid(client, _dims, _grid, 0, _nmsg, _frame) do
    # end of all generations
    send(client, :end_of_life)
  end

  def sgrid(client, dims, grid, igen, 0, frame) do
    # end of frame for this generation 
    # report to client, decrement generation and initialize next frame
    Logger.info("sgrid frame #{igen}")
    send(client, {:frame, frame})
    :erlang.garbage_collect()
    sgrid(client, dims, grid, igen - 1, map_size(grid), MapSet.new())
  end

  def sgrid(client, dims, grid, igen, nmsg, frame) do
    # build a frame from all cell updates
    receive do
      {:update, loc, state, ^igen} ->
        new_frame = frame_update(frame, loc, state)
        sgrid(client, dims, grid, igen, nmsg - 1, new_frame)
    end
  end

  # isotropic homogeneous neghborhood, just use list of pids
  # for complex rules, use map of delta => pid
  # for cyclic boundary conditions:
  # replace filters with modulo arithmetic
  @spec neighborhood(X.location(), X.dimensions(), X.grid()) :: X.neighborhood()
  defp neighborhood({i, j}, {ni, nj}, grid) do
    for di <- -1..1,
        dj <- -1..1,
        not (di == 0 and dj == 0),
        ii = i + di,
        jj = j + dj,
        1 <= ii,
        ii <= ni,
        1 <= jj,
        jj <= nj,
        into: [] do
      Map.fetch!(grid, {ii, jj})
    end
  end

  # set a new boolean state value in a frame set of occupied cells
  @spec frame_update(MapSet.t(), X.location(), X.state()) :: MapSet.t()
  defp frame_update(frame, _loc, false), do: frame
  defp frame_update(frame, loc, true), do: MapSet.put(frame, loc)
end
