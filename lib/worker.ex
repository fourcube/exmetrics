defmodule Exmetrics.Worker do
  @moduledoc false
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, %{counters: %{}, gauges: %{}, histograms: %{}}, name: Exmetrics)
  end

  ###
  # Snapshot
  ###
  @doc "Snapshot current state."
  def state() do
    GenServer.call Exmetrics, :get_state
  end

  ###
  # Gauges
  ###
  @doc "Set gauge to value n."
  def set_gauge(name, n) do
    GenServer.cast Exmetrics, {:set, [:gauges, name], n}
  end

  @doc "Get gauge value."
  def get_gauge(name) do
    v = GenServer.call Exmetrics, {:get, [:gauges, name]}
    case v do
      v when is_function(v) -> apply(v, [])
      nil -> nil
    end
  end

  @doc "Remove gauge from collection."
  def remove_gauge(name) do
    remove([:gauges, name])
  end

  defp remove(path) do
    GenServer.cast Exmetrics, {:remove, path}
  end

  ###
  # Counters
  ###
  @doc "Increment counter by n."
  def increment_counter(name, n) do
    GenServer.cast Exmetrics, {:increment_counter, name, n}
  end

  @doc "Returns the counter value with 'name'. Returns 0 if this counter is unknown."
  def get_counter(name) do
    GenServer.call Exmetrics, {:get, [:counters, name]}
  end

  @doc "Reset counter."
  def reset_counter(name, n \\ 0) do
    GenServer.cast Exmetrics, {:set, [:counters, name], n}
  end

  ###
  # Histograms
  ###
  @doc """
  Create a sliding window histogram which records metrics over 5 minutes.
  """
  def new_histogram(name, max, sigfigs) when is_integer(max) and is_integer(sigfigs) do
    init_histogram = fn _ ->
      {:ok, h} = :hdr_histogram.open(max, sigfigs)
      h
    end

    # initialize window, allocate one for a combined view ('merged')
    histograms = 0..5
    |> Enum.map(init_histogram)

    # take one for merges
    [merged|histograms] = histograms

    # pointer to the current histogram
    current = hd(histograms)

    window = %{
      index: 0,
      current: current,
      merged: merged,
      histograms: histograms
    }

    GenServer.cast Exmetrics, {:set, [:histograms, name], window}
  end

  @doc "Register a value inside a histogram."
  def record_histogram_value(name, value) when is_integer(value) do
    GenServer.cast Exmetrics, {:record_h, [:histograms, name, :current], value}
  end

  @doc "Get a full histogram."
  def get_histogram(name) do
    GenServer.call Exmetrics, {:get, [:histograms, name]}
  end

  @doc """
  Rotate the current recording window of a histogram.

  Before rotation (*current window):
    [*0 | 1 | 2 | 3 | 4]

  After rotation:
    [0 | *1 | 2 | 3 | 4]

  The window is cleared *after* it was rotated to.
  """
  def rotate_histogram(histogram) when is_bitstring(histogram) do
    case GenServer.call Exmetrics, {:get, [:histograms, histogram]} do
      nil ->
        :err_not_avail
      h -> rotate_histogram(h)
    end
  end

  def rotate_histogram({key, %{index: index, histograms: histograms} = histogram}) do
    index = index+1
    current = Enum.at(histograms, rem(index, length(histograms)))
    :hdr_histogram.reset(current)

    histogram = %{histogram | current: current, index: index}
    GenServer.cast Exmetrics, {:set, [:histograms, key], histogram}
  end

  @doc "Rotate all registered histograms."
  def rotate_all_histograms() do
    get_in(state(), [:histograms])
    |> Enum.each(&rotate_histogram/1)
  end

  def remove_histogram(histogram_name) do
    case GenServer.call Exmetrics, {:get, [:histograms, histogram_name]} do
      nil ->
        :err_not_avail
      hs ->
        # Remove all automatically registered gauges.
        Exmetrics.Histogram.automatic_histogram_gauges
        |> Enum.each(fn gauge_name -> remove_gauge "#{histogram_name}.#{gauge_name}" end)

        # Close all histogram windows
        hs
        |> Map.get(:histograms)
        |> Enum.each(&:hdr_histogram.close/1)

        # ...and the histogram which contains the merged view
        Map.get(hs, :merged)
        |> :hdr_histogram.close

        remove([:histograms, histogram_name])
        :ok
    end
  end


  ###
  # Server Functions
  ###

  def handle_call({:get, path}, _from, state) do
    {:reply, get_in(state, path), state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:increment_counter, counter_name, n}, state) do
    state = update_in(state, [:counters, counter_name], &(incr(&1, n)))
    {:noreply, state}
  end

  def handle_cast({:set, path, value}, state) do
    state = update_in(state, path, fn _ -> value end)
    {:noreply, state}
  end

  def handle_cast({:remove, path}, state) do
    state = update_in(state, path, fn _ -> nil end)
    {:noreply, state}
  end

  def handle_cast({:record_h, path, value}, state) do
    histogram = get_in(state, path)

    case histogram do
      nil -> nil
      histogram -> :hdr_histogram.record(histogram, value)
    end

    {:noreply, state}
  end

  ###
  # Utility functions
  ###
  defp incr(a, b) when is_nil(a) do
    b
  end

  defp incr(a, b) do
    a + b
  end
end
