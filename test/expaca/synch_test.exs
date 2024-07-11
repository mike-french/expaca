defmodule Expaca.SynchTest do
  use ExUnit.Case

  import Expaca.TestUtil

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
    asciis = {3, 3, @diag} |> Expaca.evolve(:synch, 3) |> to_ascii()
    assert_ascii([@diag1, @diag2, @diag3], asciis)
  end

  test "blinker" do
    asciis = {3, 3, @blinker1} |> Expaca.evolve(:synch, 3) |> to_ascii()
    assert_ascii([@blinker1, @blinker2, @blinker1], asciis)
  end

  test "toad" do
    asciis = {4, 4, @toad1} |> Expaca.evolve(:synch, 3) |> to_ascii()
    assert_ascii([@toad1, @toad2, @toad1], asciis)
  end

  test "small glider" do
    bitmaps = Expaca.evolve({4, 4, @glider1}, :synch, 5)
    asciis = to_ascii(bitmaps)
    assert_ascii([@glider1, @glider2, @glider3, @glider4, @glider5], asciis)
  end

  @tag timeout: 90_000
  test "big glider image batch" do
    d = 50

    init =
      Enum.reduce(@glider, MapSet.new(), fn {i, j}, fset ->
        MapSet.put(fset, {i, j + d - 3})
      end)

    {d, d, init} |> Expaca.evolve(:synch, 3 * d) |> to_images("s_glider")
  end

  @tag timeout: 90_000
  test "big glider image stream" do
    d = 50

    init =
      Enum.reduce(@glider, MapSet.new(), fn {i, j}, fset ->
        MapSet.put(fset, {i, j + d - 3})
      end)

    :ok = Expaca.evolve({d, d, init}, :synch, 3 * d, self())
    recv_frames(0, "s_stream")
  end

  @tag timeout: 90_000
  test "random" do
    d = 50
    random(d, d) |> Expaca.evolve(:synch, 3 * d) |> to_images("s_random")
  end
end
