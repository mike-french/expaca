defmodule Expaca.Rules do
  @moduledoc """
  Common rules for Game of Life.

  The cells still have some implementation details related to these rules,
  so it is a not a truly independent policy module.
  """

  alias Expaca.Types, as: X

  @doc """
  Calculate the neighborhood of a cell in a process grid.

  The neighborhood is a list of adjacent process addresses,
  """
  @spec neighborhood(X.location(), X.dimensions(), X.grid()) :: X.neighborhood()
  def neighborhood({i, j}, {ni, nj}, grid) do
    # for cyclic boundary conditions
    # replace filters with modulo arithmetic
    for di <- -1..1,
        dj <- -1..1,
        not (di == 0 and dj == 0),
        ii = i + di,
        jj = j + dj,
        1 <= ii,
        ii <= ni,
        1 <= jj,
        jj <= nj,
        into: [] do
      Map.fetch!(grid, {ii, jj})
    end
  end

  @doc "Game of Life update rule."
  @spec cell_update(X.occupancy_count(), X.state()) :: X.state()
  def cell_update(3, _), do: true
  def cell_update(2, true), do: true
  def cell_update(_, _), do: false
end
