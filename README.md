# Metrics

[![Build Status](https://travis-ci.org/fourcube/metrics.svg?branch=master)](https://travis-ci.org/fourcube/metrics)

This elixir project is inspired by the excellent [codahale/metrics](https://github.com/codahale/metrics) library.

It provides counters, gauges and histograms for instrumenting an elixir application.


## Usage

### Counters

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
```

### Gauges

```elixir
# Set gauge to a value
iex> Metrics.Gauge.set "my_gauge", 10
:ok
# or
# Set gauge to a function which is lazily evaluated
iex> Metrics.Gauge.set "my_gauge", fn -> 10 end

# Get value of a gauge
iex> Metrics.Gauge.get "my_gauge"
10

# Remove gauge
iex> Metrics.Gauge.remove "my_gauge"
:ok
iex> Metrics.Gauge.get "my_gauge"
nil
```

### Histograms

See [hdr_histogram_erl](https://github.com/HdrHistogram/hdr_histogram_erl) for semantics.

```elixir
# Create a new histogram with max value 1000000 and 3 significant figures precision
iex> Metrics.Histogram.new "my_histogram", 1000000, 3
:ok

# This automatically registers gauges for the histograms
#   50th percentile
#   75th percentile
#   90th percentile
#   95th percentile
#   99th percentile
#   99.9th percentile
#   Max histogram value
#   Min histogram value
#   Standard deviation
#   Total count

# Record a value inside a histogram
iex> Metrics.Histogram.record "my_histogram", 100
:ok

iex> Enum.each 0..100, &(Metrics.Histogram.record "my_histogram", &1)

# Get a snapshot of all data
iex> Metrics.snapshot
%{counters: %{},
  gauges: %{"my_histogram.Count" => 102, "my_histogram.Max" => 100,
    "my_histogram.Mean" => 50.5, "my_histogram.Min" => 0,
    "my_histogram.P50" => 50.0, "my_histogram.P75" => 76.0,
    "my_histogram.P90" => 91.0, "my_histogram.P95" => 96.0,
    "my_histogram.P99" => 100.0, "my_histogram.P999" => 100.0,
    "my_histogram.Stddev" => 29.4}, histograms: %{"my_histogram" => ""}}

# Remove a histogram
iex> Metrics.Histogram.remove "my_histogram"
:ok

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
