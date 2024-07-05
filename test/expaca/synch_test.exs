defmodule Expaca.SynchTest do
  use ExUnit.Case

  use Exa.Image.Constants

  alias Expaca.Frame

  alias Exa.Color.Col3b
  alias Exa.Image.Bitmap
  alias Exa.Image.Resize
  alias Exa.Image.ImageWriter

  @png_out_dir ["test", "output"]

  defp out_png(dir, name, i) do
    n = String.pad_leading(Integer.to_string(i), 4, "0")
    Exa.File.join(@png_out_dir ++ [dir], "#{name}_#{n}", @filetype_png)
  end

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

  # position from bottom-left in 3x3 grid
  # offset j values by h-3 to put in top-left corner
  @glider MapSet.new([{1, 1}, {2, 1}, {3, 1}, {2, 3}, {3, 2}])

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

  # -----
  # tests
  # -----

  test "diag" do
    asciis = {3, 3, @diag} |> Expaca.grid_synch(3) |> to_ascii()
    assert_ascii([@diag1, @diag2, @diag3], asciis)
  end

  test "blinker" do
    asciis = {3, 3, @blinker1} |> Expaca.grid_synch(3) |> to_ascii()
    assert_ascii([@blinker1, @blinker2, @blinker1], asciis)
  end

  test "toad" do
    asciis = {4, 4, @toad1} |> Expaca.grid_synch(3) |> to_ascii()
    assert_ascii([@toad1, @toad2, @toad1], asciis)
  end

  test "small glider" do
    bitmaps = Expaca.grid_synch({4, 4, @glider1}, 5)
    asciis = to_ascii(bitmaps)
    assert_ascii([@glider1, @glider2, @glider3, @glider4, @glider5], asciis)
  end

  @tag timeout: 90_000
  test "big glider image" do
    d = 50

    init =
      Enum.reduce(@glider, MapSet.new(), fn {i, j}, fset ->
        MapSet.put(fset, {i, j + d - 3})
      end)

    bitmaps = Expaca.grid_synch({d, d, init}, 3 * d)
    to_image(bitmaps)
  end

  # -----------------
  # private functions 
  # -----------------

  defp assert_ascii(as1, as2)
       when is_list(as1) and is_list(as2) and
              length(as1) == length(as2) do
    Enum.each(Enum.zip(as1, as2), fn {s1, s2} ->
      assert Frame.ascii_equals?(s1, s2)
    end)
  end

  defp to_ascii(bitmaps) do
    fg = ?X
    bg = ?.

    Enum.map(bitmaps, fn bmp ->
      ascii = bmp |> Bitmap.reflect_y() |> Bitmap.to_ascii(fg, bg)
      IO.puts(ascii)
      ascii
    end)
  end

  defp to_image(bitmaps, scale \\ 4) do
    fg = Col3b.gray_pc(90)
    bg = Col3b.gray_pc(25)

    Enum.reduce(bitmaps, 1, fn bmp, i ->
      bmp
      # |> IO.inspect(label: "init")
      |> Bitmap.reflect_y()
      # |> IO.inspect(label: "reflect")
      |> Bitmap.to_image(:rgb, fg, bg)
      # |> IO.inspect(label: "rgb")
      |> Resize.resize(scale)
      # |> IO.inspect(label: "scale")
      |> ImageWriter.to_file(out_png("glider", "glider", i))

      i + 1
    end)
  end
end
