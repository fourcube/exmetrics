defmodule Metrics.Worker do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, %{counters: %{}}, name: Metrics)
  end

  @doc "Increment counter by n."
  def increment_counter(name, n) do
    GenServer.cast Metrics, {:increment_counter, name, n}
  end

  @doc "Returns the counter value with 'name'. Returns 0 if this counter is unknown."
  def get_counter(name) do
    GenServer.call Metrics, {:get_counter, name}
  end

  @doc "Reset counter."
  def reset_counter(name, n \\ 0) do
    GenServer.cast Metrics, {:set_counter, name, n}
  end

  def state() do
    GenServer.call Metrics, :get_state
  end

  # Server
  def handle_cast({:set_counter, counter_name, n}, state) do
    state = update_in(state, [:counters, counter_name], fn _ -> n end)
    {:noreply, state}
  end

  def handle_cast({:increment_counter, counter_name, n}, state) do
    state = update_in(state, [:counters, counter_name], &(incr(&1, n)))
    {:noreply, state}
  end

  def handle_call({:get_counter, counter_name}, _from, state) do
    {:reply, get_in(state, [:counters, counter_name]) || 0, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  defp incr(a, b) when is_nil(a) do
    b
  end

  defp incr(a, b) do
    a + b
  end
end
