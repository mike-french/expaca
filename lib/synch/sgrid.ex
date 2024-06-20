defmodule Expaca.Synch.Sgrid do
  @moduledoc """
  Synchronous grid.
  """

  alias Expaca, as: E
  alias Expaca.Synch.Scell

  @doc "Start the synchronous grid process."
  @spec start(E.dimensions(), E.generation(), E.frame()) :: pid()
  def start(dims, ngen, frame0) do
    spawn_link(__MODULE__, :init, [self(), dims, ngen, frame0])
  end

  # initialize the grid, start all cells
  # send the cells their neighborhood connections
  # send the initial state and trigger them to start evolving
  @spec init(pid(), E.dimensions(), E.generation(), E.frame()) :: no_return()
  def init(client, {ni, nj} = dims, ngen, frame0) do
    grid =
      for j <- 1..nj, i <- 1..ni, loc = {i, j}, into: %{} do
        {loc, Scell.start(loc, self(), ngen)}
      end

    for {loc, pid} <- grid do
      send(pid, {:connect, self(), neighborhood(loc, dims, grid)})
    end

    for j <- 1..nj, i <- 1..ni, loc = {i, j} do
      send(Map.fetch!(grid, loc), {:init, self(), Map.get(frame0, loc, 0)})
    end

    sgrid(client, dims, grid, ngen, map_size(grid), %{})
  end

  @spec sgrid(
          client :: pid(),
          dims :: E.dimensions(),
          grid :: E.grid(),
          igen :: E.generation(),
          nmsg :: non_neg_integer(),
          frame :: E.frame()
        ) :: no_return()

  def sgrid(client, _dims, _grid, 0, _nmsg, %{}) do
    # end of all generations
    send(client, :end_of_life)
  end

  def sgrid(client, dims, grid, igen, 0, frame) do
    # end of frame for this generation 
    send(client, {:frame, frame})
    sgrid(client, dims, grid, igen - 1, map_size(grid), %{})
  end

  def sgrid(client, dims, grid, igen, nmsg, frame) do
    # build a frame from all cell updates
    receive do
      {:update, loc, state, ^igen} ->
        new_frame = Map.put(frame, loc, state)
        sgrid(client, dims, grid, igen, nmsg - 1, new_frame)
    end
  end

  # isotropic homogeneous neghborhood, just use list of pids
  # for complex rules, use map of delta => pid
  # for cyclic boundary conditions:
  # replace filters with modulo arithmetic
  @spec neighborhood(E.location(), E.dimensions(), E.grid()) :: E.neighborhood()
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
end
