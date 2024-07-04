defmodule Expaca.SynchTest do
  use ExUnit.Case
  alias Expaca

  alias Exa.Image.Bitmap

  doctest Expaca

  @diag MapSet.new([{1, 1}, {2, 2}, {3, 3}])

  @diag1 """
  ..X
  .X.
  X..
  """
  @diag2 """
  ...
  .X.
  ...
  """
  @diag3 """
  ...
  ...
  ...
  """

  @blinker1 """
  ...
  XXX
  ...
  """
  @blinker2 """
  .X.
  .X.
  .X.
  """

  @toad1 """
  ....
  .XXX
  XXX.
  ....
  """
  @toad2 """
  ..X.
  X..X
  X..X
  .X..
  """

  @glider1 """
  .X..
  ..X.
  XXX.
  ....
  """
  @glider2 """
  ....
  X.X.
  .XX.
  .X..
  """
  @glider3 """
  ....
  ..X.
  X.X.
  .XX.
  """
  @glider4 """
  ....
  .X..
  ..XX
  .XX.
  """
  @glider5 """
  ....
  ..X.
  ...X
  .XXX
  """

  test "diag" do
    asciis = {3, 3, @diag} |> Expaca.grid_synch(3) |> to_ascii()
    assert [@diag1, @diag2, @diag3] == asciis
  end

  test "blinker" do
    asciis = {3, 3, @blinker1} |> Expaca.grid_synch(3) |> to_ascii()
    assert [@blinker1, @blinker2, @blinker1] == asciis
  end

  test "toad" do
    asciis = {4, 4, @toad1} |> Expaca.grid_synch(3) |> to_ascii()
    assert [@toad1, @toad2, @toad1] == asciis
  end

  test "glider" do
    asciis = {4, 4, @glider1} |> Expaca.grid_synch(5) |> to_ascii()
    assert [@glider1, @glider2, @glider3, @glider4, @glider5] == asciis
  end

  defp to_ascii(bitmaps) do
    Enum.map(bitmaps, fn bmp -> 
      ascii = bmp |> Bitmap.reflect_y() |> Bitmap.to_ascii() 
      IO.puts(ascii)
      ascii
    end)
  end
end
