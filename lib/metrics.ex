defmodule Metrics do
  use Application
  require Logger

  @doc """
  Returns all registered metrics.  
  """
  def report do
    Metrics.Worker.state
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
    """
    def get(name) do
      Metrics.Worker.get_counter(name)
    end

    @doc ~S"""
    Reset counter 'name' to 0.

      iex> Metrics.Counter.reset "foo"
      iex> Metrics.Counter.get "foo"
      0
    """
    def reset(name) do
      Metrics.Worker.reset_counter(name, 0)
    end

    @doc ~S"""
    Reset counter 'name' to n.

      iex> Metrics.Counter.reset "foo", 42
      iex> Metrics.Counter.get "foo"
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
