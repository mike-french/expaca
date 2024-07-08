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
        {loc, Acell.start(loc, self)}
      end

    # send the cells their neighborhood connections
    for {loc, pid} <- grid do
      send(pid, {:connect, self(), Rules.neighborhood(loc, dims, grid)})
    end

    # send the initial state and trigger them to start evolving
    for j <- 1..nj, i <- 1..ni, loc = {i, j} do
      send(Map.fetch!(grid, loc), {:init, self, MapSet.member?(fset0, loc)})
    end

    # hack scale up the steps
    # because asynch has bitmap for every change 
    nstep = ngen * ni

    # could keep the fset state, to halt when the frame is empty
    bmap0 = Frame.to_bitmap(frame0)
    send(client, {:frame, 0, bmap0})

    agrid(client, grid, nstep, 0, bmap0)
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
          # current frame as a full bitmap
          bmap :: I.Bitmap.bitmap()
        ) :: no_return()

  def agrid(client, _grid, nstep, nstep, _bmap) do
    # end of all generations
    send(client, :end_of_frames)
  end

  def agrid(client, grid, nstep, istep, bmap) do
    # every cell update emits a new bitmap frame
    receive do
      {:update, {i, j}, state} ->
        bit = if state, do: 1, else: 0
        new_bmap = Bitmap.set_bit(bmap, {i - 1, j - 1}, bit)
        send(client, {:frame, istep, new_bmap})
        agrid(client, grid, nstep, istep + 1, new_bmap)
    end
  end
end
