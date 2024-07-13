ExUnit.start(timeout: 10000, exclude: [oom: true, benchmark: true, codegen: true, visual: true])

defmodule Expaca.TestUtil do
  use ExUnit.Case

  use Exa.Image.Constants

  alias Exa.Image.Types, as: I

  alias Exa.Binary
  alias Exa.Color.Col3b
  alias Exa.Image.Bitmap
  alias Exa.Image.Resize
  alias Exa.Image.ImageWriter

  alias Expaca.Frame

  # ascii art characters
  @fgchar ?X
  @bgchar ?.

  # grayscale RGB image pixels
  @fgcol Col3b.gray_pc(90)
  @bgcol Col3b.gray_pc(25)

  @out_dir ["test", "output"]

  def out_png(dir, name, i) do
    n = String.pad_leading(Integer.to_string(i), 4, "0")
    Exa.File.join(@out_dir ++ [dir], "#{name}_#{n}", @filetype_png)
  end

  def out_mp4(dir, name) do
    Exa.File.join(@out_dir ++ [dir], name, @filetype_mp4)
  end

  def out_gif(dir, name) do
    Exa.File.join(@out_dir ++ [dir], name, @filetype_gif)
  end 

  def file_glob(dir, name) do
    (@out_dir ++ [dir])
    |> Exa.File.join(name <> "-*", @filetype_png)
    |> Exa.String.wraps("'", "'")
  end

  def file_iseq(dir, name) do
    Exa.File.join(@out_dir ++ [dir], name <> "_%04d", @filetype_png)
  end

  # receiver for bitmap stream
  def recv_frames(igen, name) do
    receive do
      {:frame, ^igen, bmp} ->
        bmp2file(bmp, name, igen)
        recv_frames(igen + 1, name)

      :end_of_frames ->
        :ok
    end
  end

  # assert that two sequences of ascii art are equal
  def assert_ascii(as1, as2)
      when is_list(as1) and is_list(as2) and
             length(as1) == length(as2) do
    Enum.each(Enum.zip(as1, as2), fn {s1, s2} ->
      assert Frame.ascii_equals?(s1, s2)
    end)
  end

  # convert bitmap sequence to ascii art string sequence
  def to_ascii(bitmaps) do
    Enum.map(bitmaps, fn bmp ->
      ascii = bmp |> Bitmap.reflect_y() |> Bitmap.to_ascii(@fgchar, @bgchar)
      IO.puts(ascii)
      ascii
    end)
  end

  # write bitmap sequence to RGB image files
  def to_images(bmps, name) do
    Enum.reduce(bmps, 1, fn bmp, i ->
      bmp2file(bmp, name, i)
      i + 1
    end)
  end

  # convert bitmap frame to an RGB image and write to file
  def bmp2file(bmp, name, i, scale \\ 4) do
    bmp
    |> Bitmap.reflect_y()
    |> Bitmap.to_image(:rgb, @fgcol, @bgcol)
    |> Resize.resize(scale)
    |> ImageWriter.to_file(out_png(name, name, i))

    :erlang.garbage_collect()
  end

  # generate a random bitmap
  # TODO - replace this with Bitmap.random after next exa_image release
  def random(w, h) do
    row = Binary.padded_bits(w)
    buf = :rand.bytes(h * row)
    %I.Bitmap{width: w, height: h, row: row, buffer: buf}
  end
end
