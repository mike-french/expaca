defmodule Expaca.VideoTest do
  use ExUnit.Case

  import Expaca.TestUtil

  alias Exa.Image.Video

  # **************************************
  # requires that synch_test be run first
  # to populate the animation sequences
  # **************************************

  test "basic" do
    cmd = Video.ensure_installed!(:ffmpeg)
    IO.inspect(cmd, label: "FFMPEG")
    assert not is_nil(cmd)
  end

  test "glider" do
    seq = file_iseq("s_glider", "s_glider")
    mp4 = out_mp4("s_glider", "s_glider")
    to_video(seq, mp4, 12)
  end

  test "random" do
    seq = file_iseq("s_random", "s_random")
    mp4 = out_mp4("s_random", "s_random")
    to_video(seq, mp4, 12)
  end

  defp to_video(seq,mp4,frate) do

    args = [
      loglevel: "error",
      overwrite: "y",
      i: seq,
      framerate: frate,
      r: frate,
      pattern_type: "sequence",
      start_number: "0001",
      "c:v": "libx264",
      pix_fmt: "yuv420p"
    ]

    Video.from_files(mp4, args)
  end
end
