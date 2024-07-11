defmodule Expaca.VideoTest do
  use ExUnit.Case

  import Expaca.TestUtil

  alias Exa.Image.Video

  # ****************************************
  # requires that a/synch tests be run first
  # to populate the animation sequences
  # ****************************************

  test "basic" do
    cmd = Video.ensure_installed!(:ffmpeg)
    IO.inspect(cmd, label: "FFMPEG")
    assert not is_nil(cmd)
  end

  test "synch glider" do
    vtest("s_glider", 12)
  end

  test "synch random" do
    vtest("s_random", 12)
  end

  test "asynch glider" do
    vtest("a_glider", 30)
  end

  test "asynch random" do
    vtest("a_random", 30)
  end

  defp vtest(name,frate) do
    seq = file_iseq(name,name)
    mp4 = out_mp4(name,name)
    gif = out_gif(name,name)
    to_video(seq, mp4, frate)
    to_gif(seq, gif, frate)
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

  defp to_gif(seq,gif,frate) do

    args = [
      loglevel: "error",
      overwrite: "y",
      i: seq,
      framerate: frate,
      r: frate,
      pattern_type: "sequence",
      start_number: "0001",
      vf: "fps=#{frate},scale=100:-1:flags=lanczos,"<>
          "split[s0][s1];"<>
          "[s0]palettegen[p];"<>
          "[s1][p]paletteuse" 
    ]

    Video.from_files(gif, args)
  end
end
