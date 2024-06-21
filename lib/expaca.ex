defmodule Expaca do
  @moduledoc """
  EXPeriments with Asynchronous Cellular Automata.
  """

  @maxdim 256
  @maxgen 1_000

  alias Expaca.Synch.Sgrid

  @type state() :: bool()
  @type occupancy() :: non_neg_integer()
  @type dimensions() :: {pos_integer(), pos_integer()}
  @type location() :: {pos_integer(), pos_integer()}
  @type frame() :: MapSet.t()
  @type generation() :: non_neg_integer()
  @type grid() :: %{location() => pid()}
  @type neighborhood() :: [pid(), ...]

  @doc """
  Run a synchronized grid simulation.

  Dimensions `{ni,nj}` are the size of the 2D grid in I and J directions.

  A cell location is a pair of 1-based integer indexes `{i,j}`.

  The initial frame is a set of occupied locations.

  The initial state may also be provided as a string,
  with `X` for occupied and `.` for empty. 
  Rows are divided by a single newline `\\n`.
  The dimensions are assumed to match.
  The string is in row-major order, 
  and the origin is in the lower left,
  so the first line in the string is the j=nj row for varying i.
  For example, a glider:

  ```
  \"\"\"
  .X..
  ..X.
  XXX.
  ....
  \"\"\"
  ```

  The number of generations is the number of steps in the simulation to perform.
  Each step will generate a complete synchronous frame of all cell states.
  """
  @spec grid_synch(dimensions(), String.t() | frame(), generation()) :: [String.t()]
  def grid_synch(dims, frame0, ngen \\ 100)

  def grid_synch({ni, nj} = dims, frame0, ngen)
      when is_integer(ni) and 3 <= ni and ni <= @maxdim and
             is_integer(nj) and 3 <= nj and nj <= @maxdim and
             is_integer(ngen) and 1 <= ngen and ngen <= @maxgen do
    do_synch(dims, frame0, ngen)
  end

  @spec do_synch(dimensions(), String.t() | frame(), generation()) :: [String.t()]

  defp do_synch({_ni, nj} = dims, str, ngen) when is_binary(str) do
    do_synch(dims, str2frm(str, 1, nj), ngen)
  end

  defp do_synch(dims, frame0, ngen) when is_struct(frame0, MapSet) do
    Sgrid.start(dims, ngen, frame0)
    recv_frames(dims)
  end

  @spec recv_frames(dimensions(), [String.t()]) :: [String.t()]
  defp recv_frames(dims, frames \\ []) do
    receive do
      {:frame, frame} -> recv_frames(dims, [frm2str(frame,dims)|frames])
      :end_of_life -> Enum.reverse(frames)
    end
  end

  # convert a string frame to a map indexed by locations
  # assumes format is correct, with consistent rows
  # and assume it matches the dimension specification
  @spec str2frm(String.t(), pos_integer(), pos_integer(), frame()) :: frame()
  defp str2frm(str, i, j, frame \\ MapSet.new())

  defp str2frm(<<?\n, rest::binary>>, _i, j, frame), do: str2frm(rest, 1, j - 1, frame)

  defp str2frm(<<?X, rest::binary>>, i, j, frame) do
    str2frm(rest, i + 1, j, MapSet.put(frame, {i, j}))
  end

  defp str2frm(<<?., rest::binary>>, i, j, frame), do: str2frm(rest, i + 1, j, frame)

  defp str2frm(<<>>, _i, _j, frame), do: frame

  # convert a map frame to a string 
  @spec frm2str(frame(), dimensions()) :: String.t()
  defp frm2str(frame, {ni, nj}) do
    Enum.reduce(nj..1//-1, "", fn j, str ->
      Enum.reduce(1..ni, str, fn i, str ->
        c = if MapSet.member?(frame, {i,j}), do: ?X, else: ?.
        <<str::binary, c>>
      end) <> "\n"
    end)
  end
end
