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

  The `client` argument determines the output behavior:
  - `nil` (default) means block, accumulate all frames, 
     then return the full sequence
  - `pid` client process means prompt return, 
     then the grid simulation streams events to the client process

  The event stream is:
  - `{:frame, i, bitmap}` for each frame
  - `:end_of_frames` 

  where `i` is a 0-based frame number, 
  and frame `0` is the initial starting state.

  To post-process bitmap frames, use:
  - `Exa.Image.Bitmap` to convert to ASCII art, and grayscale or RGB images
  - `Exa.Image.Video` to make a video (if you have ffmpeg installed)
  """
  @spec grid_synch(X.frame() | X.asciiart() | %I.Bitmap{}, X.generation(), nil | pid()) ::
          :ok | [%I.Bitmap{}]
  def grid_synch(frame0, ngen \\ 100, client \\ nil)

  def grid_synch(ascii0, ngen, client) when is_asciiart(ascii0) and is_ngen(ngen) do
    ascii0 |> Frame.from_ascii() |> Sgrid.start(ngen, client)
    recv_frames(client)
  end

  def grid_synch(%I.Bitmap{} = bmp0, ngen, client) when is_ngen(ngen) do
    bmp0 |> Frame.from_bitmap() |> Sgrid.start(ngen, client)
    recv_frames(client)
  end

  def grid_synch(frame0, ngen, client) when is_frame(frame0) and is_ngen(ngen) do
    frame0 |> Sgrid.start(ngen, client)
    recv_frames(client)
  end

  # -----------------
  # private functions
  # -----------------

  @spec recv_frames(nil | pid(), non_neg_integer(), [%I.Bitmap{}]) :: :ok | [%I.Bitmap{}]
  defp recv_frames(client, igen \\ 0, bitmaps \\ [])

  # we are the client, so accumulate frames here
  defp recv_frames(nil, igen, bitmaps) do
    receive do
      {:frame, ^igen, bitmap} -> recv_frames(nil, igen + 1, [bitmap | bitmaps])
      :end_of_frames -> Enum.reverse(bitmaps)
    end
  end

  # calling program is client, so prompt return
  defp recv_frames(_pid, 0, []), do: :ok
end
