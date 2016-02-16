defmodule Metrics.Worker do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, %{counters: %{}, gauges: %{}, histograms: %{}}, name: Metrics)
  end

  ###
  # Snapshot
  ###
  @doc "Snapshot current state."
  def state() do
    GenServer.call Metrics, :get_state
  end

  ###
  # Gauges
  ###
  @doc "Set gauge to value n."
  def set_gauge(name, n) do
    GenServer.cast Metrics, {:set, [:gauges, name], n}
  end

  @doc "Get gauge value."
  def get_gauge(name) do
    v = GenServer.call Metrics, {:get, [:gauges, name]}
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
    GenServer.cast Metrics, {:remove, path}
  end

  ###
  # Counters
  ###
  @doc "Increment counter by n."
  def increment_counter(name, n) do
    GenServer.cast Metrics, {:increment_counter, name, n}
  end

  @doc "Returns the counter value with 'name'. Returns 0 if this counter is unknown."
  def get_counter(name) do
    GenServer.call Metrics, {:get, [:counters, name]}
  end

  @doc "Reset counter."
  def reset_counter(name, n \\ 0) do
    GenServer.cast Metrics, {:set, [:counters, name], n}
  end

  ###
  # Histograms
  ###

  @doc "Create a new histogram instance."
  def new_histogram(name, max, sigfigs) when is_integer(max) and is_integer(sigfigs) do
    {:ok, histogram} = :hdr_histogram.open(max, sigfigs)
    GenServer.cast Metrics, {:set, [:histograms, name], histogram}
    histogram
  end

  @doc "Register a value inside a histogram."
  def record_histogram_value(name, value) when is_integer(value) do
    GenServer.cast Metrics, {:record_h, [:histograms, name], value}
  end

  @doc "Get a full histogram."
  def get_histogram(name) do
    GenServer.call Metrics, {:get, [:histograms, name]}
  end

  def remove_histogram(histogram_name) do
    case GenServer.call Metrics, {:get, [:histograms, histogram_name]} do
      nil ->
        :err_not_avail
      h ->
        # Remove all automatically registered gauges.
        Metrics.Histogram.automatic_histogram_gauges
        |> Enum.each(fn gauge_name -> remove_gauge "#{histogram_name}.#{gauge_name}" end)

        # Close the histogram
        :hdr_histogram.close(h)
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
