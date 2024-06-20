defmodule Expaca do
  @moduledoc """
  EXPeriments with Asynchronous Cellular Automata.
  """

  @maxdim 256
  @maxgen 1_000

  alias Expaca.Synch.Sgrid

  @type state() :: 0 | 1
  @type occupancy() :: non_neg_integer()
  @type dimensions() :: {pos_integer(), pos_integer()}
  @type location() :: {pos_integer(), pos_integer()}
  @type frame() :: %{location() => state()}
  @type generation() :: non_neg_integer()
  @type grid() :: %{location() => pid()}
  @type neighborhood() :: [pid(), ...]

  @doc """
  Run a grid simulation.

  Dimensions `{ni,nj}` are the size of the 2D grid in I and J directions.

  A cell location is a pair of 1-based integer indexes `{i,j}`.

  The initial frame is a map of locations to state values (0, 1).
  The default state is empty (0), so only occupied cells need to be provided.

  The initial state may also be provided as a string,
  with `X` for occupied and `.` for empty. 
  Rows are divided by a single newline `\\n`.
  The dimensions are assumed to match.
  The string is in row-major order, 
  and the origin is in the lower right,
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

  defp do_synch({_ni, nj} = dims, str, ngen) when is_binary(str) do
    do_synch(dims, str2frm(str, 1, nj), ngen)
  end

  defp do_synch(dims, frame0, ngen) when is_map(frame0) do
    Sgrid.start(dims, ngen, frame0)
    recv_frames(dims)
  end

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
  defp str2frm(str, i, j, frame \\ %{})

  defp str2frm(<<?\n, rest::binary>>, _i, j, frame), do: str2frm(rest, 1, j - 1, frame)

  defp str2frm(<<c, rest::binary>>, i, j, frame) when c in [?X, ?.] do
    str2frm(rest, i + 1, j, Map.put(frame, {i, j}, state(c)))
  end

  defp str2frm(<<>>, _i, _j, frame), do: frame

  # map char to state value
  @spec state(?. | ?X) :: state()
  defp state(?.), do: 0
  defp state(?X), do: 1

  # convert a map frame to a string 
  # the frame may be sparse, with just occupied cells
  @spec frm2str(E.frame(), E.dimensions()) :: String.t()
  defp frm2str(frame, {ni, nj}) do
    Enum.reduce(nj..1//-1, "", fn j, str ->
      Enum.reduce(1..ni, str, fn i, str ->
        append(str, Map.get(frame, {i, j}, 0))
      end) <> "\n"
    end)
  end

  # append char to string frame based on state value
  defp append(row, 0), do: <<row::binary, ?.>>
  defp append(row, 1), do: <<row::binary, ?X>>
end
