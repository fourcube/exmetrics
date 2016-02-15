defmodule Metrics.Worker do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, %{counters: %{}, gauges: %{}}, name: Metrics)
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
    GenServer.call Metrics, {:get, [:gauges, name]}
  end

  @doc "Remove gauge from collection."
  def remove_gauge(name) do
    GenServer.cast Metrics, {:remove, [:gauges, name]}
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
