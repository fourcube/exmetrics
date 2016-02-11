# Metrics

[![Build Status](https://travis-ci.org/fourcube/metrics.svg?branch=master)](https://travis-ci.org/fourcube/metrics)

This elixir project is inspired by the excellent [codahale/metrics](https://github.com/codahale/metrics) library.

It library provides counters, ~~gauges~~ and ~~histograms~~ for instrumenting an application.


## Usage

```elixir
# Increment a counter
iex> Metrics.Counter.incr "my_counter"
:ok

iex> Metrics.Counter.get "my_counter"
1

# Add to a counter
iex> Metrics.Counter.add "my_counter", 5
:ok

iex> Metrics.Counter.get "my_counter"
6

# Reset a counter
iex> Metrics.Counter.reset "my_counter"
:ok

iex> Metrics.Counter.get "my_counter"
0

# Get all data

iex> Metrics.report
%{counters: %{"my_counter" => 0}}
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add metrics to your list of dependencies in `mix.exs`:

        def deps do
          [{:metrics, "~> 0.0.1"}]
        end

  2. Ensure metrics is started before your application:

        def application do
          [applications: [:metrics]]
        end
