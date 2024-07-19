defmodule Expaca.Agrid do
  @moduledoc """
  Asynchronous grid implemented as a 
  connected set of asynchronous processes.
  """
  require Logger

  alias Exa.Image.Types, as: I
  alias Exa.Image.Bitmap

  alias Expaca.Types, as: X

  alias Expaca.Acell
  alias Expaca.Frame
  alias Expaca.Rules

  # timeout for grid aggregator
  @grid_timeout 1_000

  @doc "Start the asynchronous grid process."
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
  def init({ni, nj, fset0} = frame0, ngen, client) do
    self = self()
    dims = {ni, nj}

    # initialize the grid, start all cells
    grid =
      for j <- 1..nj, i <- 1..ni, loc = {i, j}, into: %{} do
        {loc, loc |> Rules.hash() |> Acell.start(self)}
      end

    # send the cells their neighborhood connections
    for {loc, pid} <- grid do
      send(pid, {:connect, self(), Rules.neighborhood(loc, dims, grid)})
    end

    # send the initial state and trigger start of evolution
    for j <- 1..nj, i <- 1..ni, loc = {i, j} do
      send(Map.fetch!(grid, loc), {:init, self, MapSet.member?(fset0, loc)})
    end

    # hack to scale up the steps
    # because asynch has whole bitmap for every cell change 
    nstep = ngen * ni

    bmap0 = Frame.to_bitmap(frame0)
    send(client, {:frame, 0, bmap0})
    agrid(client, grid, nstep, 1, MapSet.size(fset0), bmap0)
  end

  # main loop
  @spec agrid(
          # client to send output
          client :: pid(),
          # grid manager process address
          grid :: X.grid(),
          # total number of steps
          nstep :: X.generation(),
          # current step number
          istep :: non_neg_integer(),
          # current count of occupied cells
          size :: E.count0(),
          # current frame as a full bitmap
          bmap :: I.Bitmap.bitmap()
        ) :: no_return()

  defp agrid(client, grid, nstep, istep, size, bmap) do
    # empty frame ends the simulation
    if istep == nstep or size == 0 do
      send(client, :end_of_frames)
      exit(:normal)
    end

    receive do
      {:update, hash, state} ->
        {i, j} = Rules.unhash(hash)
        bit = if state, do: 1, else: 0
        new_size = size + (2 * bit - 1)
        new_bmap = Bitmap.set_bit(bmap, {i - 1, j - 1}, bit)
        :erlang.garbage_collect()
        send(client, {:frame, istep, new_bmap})
        agrid(client, grid, nstep, istep + 1, new_size, new_bmap)
    after
      @grid_timeout ->
        send(client, :end_of_frames)
        exit(:timeout)
    end
  end
end
