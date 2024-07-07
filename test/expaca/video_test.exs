defmodule Expaca.VideoTest do
  use ExUnit.Case

  use Exa.Image.Constants

  alias Exa.Image.Video

  @filetype_mp4 "mp4"

  @png_out_dir ["test", "output"]

  def file_glob(dir, name) do
    (@png_out_dir ++ [dir])
    |> Exa.File.join(name <> "-*", @filetype_png)
    |> Exa.String.wraps("'", "'")
  end

  def file_iseq(dir, name) do
    (@png_out_dir ++ [dir])
    |> Exa.File.join(name <> "_%04d", @filetype_png)

    # protect the glob * symbol
    # |> Exa.String.wraps("'", "'")
  end

  def out_mp4(dir, name) do
    Exa.File.join(@png_out_dir ++ [dir], name, @filetype_mp4)
  end

  test "basic" do
    cmd = Video.ensure_installed!(:ffmpeg)
    IO.inspect(cmd, label: "FFMPEG")
    assert not is_nil(cmd)
  end

  # requires that synch_test be run first
  # to populate the glider images

  test "glider" do
    Logger.configure(level: :error)
    seq = file_iseq("glider", "glider")
    mp4 = out_mp4("glider", "glider")

    args = [
      overwrite: "y",
      framerate: 12,
      # globbing not available on Windows
      # pattern_type: "glob",
      pattern_type: "sequence",
      start_number: "0001",
      i: seq,
      "c:v": "libx264",
      r: 12,
      pix_fmt: "yuv420p"
    ]

    Video.from_files(mp4, args)
  end
end
