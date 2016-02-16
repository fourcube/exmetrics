defmodule Exmetrics.Rotator do
  @moduledoc false
  require Logger

  @doc """
  Start a task that rotates a windowed histogram every minute.
  """
  def start_link do
    Task.start_link(fn -> rotate end)
  end

  defp rotate do
    :timer.sleep(60 * 1000)
    Exmetrics.Worker.rotate_all_histograms()

    # recurse
    rotate
  end
end
