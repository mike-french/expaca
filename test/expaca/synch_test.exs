defmodule Expaca.SynchTest do
  use ExUnit.Case
  alias Expaca

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
    frames = Expaca.grid_synch({3, 3}, @diag, 3)
    Enum.each(frames, &IO.puts/1)
    assert [@diag1, @diag2, @diag3] == frames
  end

  test "blinker" do
    frames = Expaca.grid_synch({3, 3}, @blinker1, 3)
    Enum.each(frames, &IO.puts/1)
    assert [@blinker1, @blinker2, @blinker1] == frames
  end

  test "toad" do
    frames = Expaca.grid_synch({4, 4}, @toad1, 3)
    Enum.each(frames, &IO.puts/1)
    assert [@toad1, @toad2, @toad1] == frames
  end

  test "glider" do
    frames = Expaca.grid_synch({4, 4}, @glider1, 5)
    Enum.each(frames, &IO.puts/1)
    assert [@glider1, @glider2, @glider3, @glider4, @glider5] == frames
  end
end
