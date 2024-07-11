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

  @doc "Game of Life update rule, based on occupancy count."
  @spec count_update(X.occupancy_count(), X.state()) :: X.state()
  def count_update(3, _), do: true
  def count_update(2, true), do: true
  def count_update(_, _), do: false

  @doc "Game of Life update rule, based on occupancy map."
  @spec hood_update(X.occupancy_map(), X.state()) :: X.state()
  def hood_update(hood, state), do: hood |> occupancy() |> count_update(state)

  @doc "Get occupancy from neighborhood map."
  @spec occupancy(X.occupancy_map()) :: X.occupancy_count()
  def occupancy(hood) do
    Enum.reduce(hood, 0, fn
      {_pid, false}, occ -> occ
      {_pid, true}, occ -> occ + 1
    end)
  end
end
