defmodule Expaca.Video do
  @moduledoc """
  A command line interface for video creation 
  and frame extraction using `ffmpeg`.

  There must be an existing `ffmpeg` installation.
  `ffmpeg` is not linked and called as a library.

  https://ffmpeg.org/download.html

  Keyword ptions follow the command line interface:

  https://ffmpeg.org/ffmpeg.html

  Except that the standalone overwrite options `-y` and `-n` 
  must be specified as a kv pair in the keyword options list.<br>
  For example: `... overwrite: "y" ...
  """
  require Logger
  import Exa.Types
  alias Exa.Types, as: E
 
  # the ffmpeg executable
  @ffmpeg "ffmpeg"

  # allowed options that are passed through to ffmpeg
  @options [
    "c:v",
    "f",
    "i",
    "framerate",
    "loglevel",
    # "overwrite"
    "pattern_type",
    "pix_fmt",
    "r",
    "s:v",
    "start_number"
  ]

  @doc """
  Get the ffmpeg installed executable path. 
  """
  @spec ensure_ffmpeg() :: nil | E.filename()
  def ensure_ffmpeg(), do: System.find_executable(@ffmpeg)

  @doc """
  Ensure that ffmpeg is installed and accessible 
  on the OS command line, otherwise raise an error.
  """
  @spec ensure_ffmpeg!() :: E.filename()
  def ensure_ffmpeg!() do
    case System.find_executable(@ffmpeg) do
      nil ->
        msg = "Cannot find '#{@ffmpeg}' executable"
        Logger.error(msg)
        path = System.fetch_env("PATH")
        Logger.info("PATH=#{path}")
        raise RuntimeError, message: msg

      exe ->
        exe
    end
  end

  @doc """
  Create a video from a sequence of frame images.
  """
  @spec create(E.filename(), E.options()) :: :ok | {:error, any()}
  def create(vfile, opts) when is_filename(vfile) do
    ensure_ffmpeg!()
    Exa.File.ensure_dir!(vfile)
    args = ["-loglevel", level(Logger.level())|options(opts)] ++ [vfile]

    case System.cmd(@ffmpeg, args, []) do
      {"", 0} ->
        :ok

      {msg, status} when status > 0 ->
        Logger.error("FAILED [#{status}]: " <> inspect(msg))
        {:error, msg}
    end
  rescue
    err ->
      Logger.error("ERROR: " <> inspect(err))
      {:error, err}
  end

  defp options(opts) do
    opts 
    |> Enum.reverse()
    |> Enum.reduce([], fn
      {k, v}, args ->
        case to_string(k) do
          "overwrite" when v in ["y","n"] -> ["-#{v}" | args] 
          kstr when kstr in @options -> ["-#{kstr}", "#{v}" | args]
          _ -> args
        end
    end)
  end

  defp level(:none), do: "‘quiet" 
  defp level(:emergency), do: "panic" 
  defp level(:alert), do: "fatal" 
  defp level(:critical), do: "fatal" 
  defp level(:error), do: "error" 
  defp level(:warning), do: "warning" 
  defp level(:warn), do: "warning" 
  defp level(:notice), do: "info" 
  defp level(:info), do: "info" 
  defp level(:debug), do: "debug" 
  defp level(:all), do: "trace" 
end
