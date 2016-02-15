defmodule Metrics do
  use Application
  require Logger

  @doc """
  Returns all registered metrics.

  iex> Metrics.Counter.incr("sample_counter")
  iex> Metrics.Gauge.set("sample_gauge", 1)
  iex> snapshot = Metrics.snapshot
  iex> get_in(snapshot, [:counters, "sample_counter"])
  1
  iex> get_in(snapshot, [:gauges, "sample_gauge"])
  1

  """
  @spec snapshot() :: map()
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
      :ok
      iex> Metrics.Gauge.get "foo"
      1
    """
    @spec set(String.t, integer) :: atom
    def set(name, value) do
      Metrics.Worker.set_gauge(name, value)
    end

    @doc ~S"""
    Get the value of a gauge.

      iex> Metrics.Gauge.set "bar", 10
      :ok
      iex> Metrics.Gauge.get "bar"
      10

      iex> Metrics.Gauge.get "doesnt_exist"
      nil
    """
    @spec get(String.t) :: (integer | nil)
    def get(name) do
      Metrics.Worker.get_gauge(name)
    end

    @doc ~S"""
    Remove a gauge from the metrics collection.

      iex> Metrics.Gauge.set "to_be_removed", 10
      :ok
      iex> Metrics.Gauge.get "to_be_removed"
      10
      iex> Metrics.Gauge.remove "to_be_removed"
      :ok
      iex> Metrics.Gauge.get "to_be_removed"
      nil
    """
    @spec get(String.t) :: atom
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
      :ok
      iex> Metrics.Counter.get "foo"
      1
    """
    @spec incr(String.t) :: atom
    def incr(name) do
      Metrics.Worker.increment_counter(name, 1)
    end

    @doc ~S"""
    Increments the counter 'name' by n.

      iex> Metrics.Counter.add "bar", 5
      :ok
      iex> Metrics.Counter.get "bar"
      5
    """
    @spec add(String.t, integer) :: atom
    def add(name, n) when is_integer(n)  do
      Metrics.Worker.increment_counter(name, n)
    end

    @doc ~S"""
    Gets the value of a counter.

      iex> Metrics.Counter.add "baz", 42
      :ok
      iex> Metrics.Counter.get "baz"
      42

      iex> Metrics.Counter.get "doesnt_exist"
      nil
    """
    @spec get(String.t) :: integer | nil
    def get(name) do
      Metrics.Worker.get_counter(name)
    end

    @doc ~S"""
    Reset counter 'name' to 0.

      iex> Metrics.Counter.reset "reset_to_zero"
      :ok
      iex> Metrics.Counter.get "reset_to_zero"
      0
    """
    @spec reset(String.t) :: atom
    def reset(name) do
      Metrics.Worker.reset_counter(name, 0)
    end

    @doc ~S"""
    Reset counter 'name' to n.

      iex> Metrics.Counter.reset "reset_to_fourty_two", 42
      :ok
      iex> Metrics.Counter.get "reset_to_fourty_two"
      42
    """
    @spec reset(String.t, integer) :: atom
    def reset(name, n) when is_integer(n) do
      Metrics.Worker.reset_counter(name, n)
    end
  end

  defmodule Histogram do
    @moduledoc """
    Provides histograms based on
    (hdr_histogram)[https://github.com/HdrHistogram/hdr_histogram_erl.git].

    Use a histogram to track the distribution of a stream of values (e.g., the
    latency associated with HTTP requests).
    """
    @doc """
    Create a new histogram.

      iex> Metrics.Histogram.new "sample_histogram", 1000000, 3
      :ok
    """
    @spec new(String.t, integer, integer) :: atom
    def new(name, max, sigfigs \\ 3) do
      Metrics.Worker.new_histogram(name, max, sigfigs)
    end

    @doc """
    Get a full histogram.

      iex> Metrics.Histogram.new "h1", 1000, 3
      :ok
      iex> h = Metrics.Histogram.get "h1"
      iex> :hdr_histogram.get_total_count(h)
      0

    """
    @spec get(String.t) :: :hdr_histogram
    def get(name) do
      Metrics.Worker.get_histogram(name)
    end

    @doc """
    Record a value in a histogram.

      iex> Metrics.Histogram.new "h2", 1000, 3
      :ok
      iex> Metrics.Histogram.record("h2", 5)
      iex> Metrics.Histogram.get("h2") |> :hdr_histogram.max
      5

    """
    @spec record(String.t, integer) :: atom
    def record(name, value) do
      Metrics.Worker.record_histogram_value(name, value)
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
