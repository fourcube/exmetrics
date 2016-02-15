defmodule Metrics do
  use Application
  require Logger

  @doc """
  Returns all registered metrics.
  """
  def snapshot do
    Metrics.Worker.state
  end

  defmodule Gauge do
    @moduledoc """
    Gauges measure numeric values of a metric at the current point in time.

    e.g. "currently active threads"
    """

    @doc ~S"""
    Set a gauge to a certain value.

      iex> Metrics.Gauge.set "foo", 1
      iex> Metrics.Gauge.get "foo"
      1
    """
    def set(name, value) do
      Metrics.Worker.set_gauge(name, value)
    end

    @doc ~S"""
    Get the value of a gauge.

      iex> Metrics.Gauge.set "bar", 10
      iex> Metrics.Gauge.get "bar"
      10

      iex> Metrics.Gauge.get "doesnt_exist"
      nil
    """
    def get(name) do
      Metrics.Worker.get_gauge(name)
    end

    @doc ~S"""
    Remove a gauge from the metrics collection.

      iex> Metrics.Gauge.set "to_be_removed", 10
      iex> Metrics.Gauge.get "to_be_removed"
      10
      iex> Metrics.Gauge.remove "to_be_removed"
      iex> Metrics.Gauge.get "to_be_removed"
      nil
    """
    def remove(name) do
      Metrics.Worker.remove_gauge(name)
    end
  end

  defmodule Counter do
    @moduledoc """
    Counters represent integer values that increase monotonically.
    """

    @doc ~S"""
    Increments the counter 'name' by 1.

      iex> Metrics.Counter.incr "foo"
      iex> Metrics.Counter.get "foo"
      1
    """
    def incr(name) do
      Metrics.Worker.increment_counter(name, 1)
    end

    @doc ~S"""
    Increments the counter 'name' by n.

      iex> Metrics.Counter.add "bar", 5
      iex> Metrics.Counter.get "bar"
      5
    """
    def add(name, n) when is_integer(n)  do
      Metrics.Worker.increment_counter(name, n)
    end

    @doc ~S"""
    Gets the value of a counter.

      iex> Metrics.Counter.add "baz", 42
      iex> Metrics.Counter.get "baz"
      42

      iex> Metrics.Counter.get "doesnt_exist"
      nil
    """
    def get(name) do
      Metrics.Worker.get_counter(name)
    end

    @doc ~S"""
    Reset counter 'name' to 0.

      iex> Metrics.Counter.reset "reset_to_zero"
      iex> Metrics.Counter.get "reset_to_zero"
      0
    """
    def reset(name) do
      Metrics.Worker.reset_counter(name, 0)
    end

    @doc ~S"""
    Reset counter 'name' to n.

      iex> Metrics.Counter.reset "reset_to_fourty_two", 42
      iex> Metrics.Counter.get "reset_to_fourty_two"
      42
    """
    def reset(name, n) when is_integer(n) do
      Metrics.Worker.reset_counter(name, n)
    end
  end

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      worker(Metrics.Worker, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Metrics.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
