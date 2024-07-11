defmodule Expaca.AsynchTest do
  use ExUnit.Case

  import Expaca.TestUtil

  doctest Expaca

  @diag1 """
  ..X
  .X.
  X..
  """

  @blinker1 """
  ...
  XXX
  ...
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

  # -----
  # tests
  # -----

  test "diag" do
    {3, 3, @diag1} |> Expaca.evolve(:asynch, 3) |> to_ascii()
  end

  test "blinker" do
    {3, 3, @blinker1} |> Expaca.evolve(:asynch, 3) |> to_ascii()
  end

  test "toad1" do
    {4, 4, @toad1} |> Expaca.evolve(:asynch, 3) |> to_ascii()
  end

  test "toad2" do
    {4, 4, @toad2} |> Expaca.evolve(:asynch, 3) |> to_ascii()
  end

  test "small glider" do
    {4, 4, @glider1} |> Expaca.evolve(:asynch, 5) |> to_ascii()
  end

  @tag timeout: 120_000
  test "big glider image batch" do
    d = 20

    init =
      Enum.reduce(@glider, MapSet.new(), fn {i, j}, fset ->
        MapSet.put(fset, {i, j + d - 3})
      end)

    {d, d, init} |> Expaca.evolve(:asynch, 3*d) |> to_images("a_glider")
  end

  @tag timeout: 120_000
  test "big glider image stream" do
    d = 20

    init =
      Enum.reduce(@glider, MapSet.new(), fn {i, j}, fset ->
        MapSet.put(fset, {i, j + d - 3})
      end)

    :ok = Expaca.evolve({d, d, init}, :asynch, 3*d, self())
    recv_frames(0, "a_stream")
  end

  @tag timeout: 120_000
  test "random stream" do
    d = 20
    init = random(d, d)
    init |> Exa.Image.Bitmap.to_ascii() |> IO.puts()
    :ok = Expaca.evolve(init, :asynch, 3 * d, self()) 
    recv_frames(0, "a_random")
  end
end
