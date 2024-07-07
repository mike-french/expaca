defmodule Expaca do
  @moduledoc """
  EXPeriments with Asynchronous Cellular Automata.
  """
  alias Exa.Image.Types, as: I

  import Expaca.Types
  alias Expaca.Types, as: X

  alias Expaca.Frame
  alias Expaca.Synch.Sgrid

  # ----------------
  # public interface
  # ----------------

  @doc """
  Run a synchronized grid simulation.

  Dimensions `{w,h}` are the size of the 2D grid in I and J directions.

  A cell location is a pair of 1-based integer indexes `{i,j}`.

  The initial state can be specified as either:
  - frame (MapSet) of occupied locations (with dimensions)
  - string ascii art where `'X'` is occupied and `'.'` is empty (with dimensions)
  - Exa Bitmap containing a bitstring buffer

  For a string state, rows are divided by a single newline `\\n`.
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

  The output is a sequence of bitmaps.
  Use `Exa.Image.Bitmap` to convert to ASCII art and 1- or 3-byte images.
  Use `Exa.Image.Video` to make a video, if you have ffmpeg installed.
  """
  @spec grid_synch(X.frame() | X.asciiart() | %I.Bitmap{}, X.generation()) :: [%I.Bitmap{}]
  def grid_synch(frame0, ngen \\ 100)

  def grid_synch({w, h, _str} = ascii0, ngen) when is_asciiart(ascii0) and is_ngen(ngen) do
    ascii0 |> Frame.from_ascii() |> Sgrid.start(ngen)
    recv_frames({w, h})
  end

  def grid_synch(%I.Bitmap{width: w, height: h} = bmp0, ngen) do
    bmp0 |> Frame.from_bitmap() |> Sgrid.start(ngen)
    recv_frames({w, h})
  end

  def grid_synch({w, h, _} = frame0, ngen) when is_frame(frame0) and is_ngen(ngen) do
    frame0 |> Sgrid.start(ngen)
    recv_frames({w, h})
  end

  # -----------------
  # private functions
  # -----------------

  @spec recv_frames(X.dimensions(), [%I.Bitmap{}]) :: [%I.Bitmap{}]
  defp recv_frames({w, h} = dims, bitmaps \\ [], i \\ 1) do
    receive do
      {:frame, fset} -> recv_frames(dims, [Frame.to_bitmap({w, h, fset}) | bitmaps], i + 1)
      :end_of_life -> Enum.reverse(bitmaps)
    end
  end
end
