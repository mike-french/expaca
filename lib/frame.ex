defmodule Expaca.Frame do
  @moduledoc """
  A sparse frame using a set of occupied locations."
  """

  import Exa.Types
  alias Exa.Types, as: E

  import Exa.Image.Types
  alias Exa.Image.Types, as: I

  alias Exa.Image.Bitmap

  alias Expaca.Types, as: X

  @doc "Create a new empty frame."
  @spec new(I.size(), I.size()) :: X.frame()
  def new(w, h) when is_size(w) and is_size(h), do: {w, h, MapSet.new()}

  @doc "Convert a bitmap to a frame."
  @spec from_bitmap(%I.Bitmap{}) :: X.frame()
  def from_bitmap(%I.Bitmap{width: w, height: h} = bmp) do
    fset =
      Bitmap.reduce(bmp, MapSet.new(), fn i, j, b, fset ->
        case b do
          0 -> fset
          1 -> MapSet.put(fset, {i + 1, j + 1})
        end
      end)

    {w, h, fset}
  end

  @doc "Convert an ascii string to a frame."
  @spec from_ascii(X.asciiart()) :: X.frame()
  def from_ascii({w, h, str})
      when is_size(w) and is_size(h) and is_string(str) and
             byte_size(str) == h * (w + 1) do
    {w, h, asc(str, 1, h, MapSet.new())}
  end

  @spec asc(String.t(), E.index1(), E.index1(), MapSet.t()) :: MapSet.t()
  defp asc(<<?., rest::binary>>, i, j, f), do: asc(rest, i + 1, j, f)
  defp asc(<<?X, rest::binary>>, i, j, f), do: asc(rest, i + 1, j, MapSet.put(f, {i, j}))
  defp asc(<<?\n, rest::binary>>, _i, j, f), do: asc(rest, 1, j - 1, f)
  defp asc(<<>>, _i, _j, f), do: f

  @doc "Convert a frame to a Bitmap."
  @spec to_bitmap(X.frame()) :: %I.Bitmap{}
  def to_bitmap({w, h, f}) when is_size(w) and is_size(h) and is_struct(f, MapSet) do
    Bitmap.new(w, h, fn {i, j} -> MapSet.member?(f, {i + 1, j + 1}) end)
  end

  @doc "Convert a frame to an ascii string."
  @spec to_ascii(X.frame()) :: String.t()
  def to_ascii(frame) do
    frame |> to_bitmap() |> Bitmap.reflect_y() |> Bitmap.to_ascii(?X, ?.)
  end
end
