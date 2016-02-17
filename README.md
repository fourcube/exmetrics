# exmetrics

[![Build Status](https://travis-ci.org/fourcube/metrics.svg?branch=master)](https://travis-ci.org/fourcube/metrics)
[![Docs](https://img.shields.io/badge/docs-hex.pm-blue.svg)](http://hexdocs.pm/exmetrics)

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

See [hdr\_histogram\_erl](https://github.com/HdrHistogram/hdr_histogram_erl) for semantics.

```elixir
# Create a new histogram with max value 1000000 and 3 significant figures precision
iex> Metrics.Histogram.new "my_histogram", 1000000, 3
:ok

# This automatically registers gauges for the histogram's
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
    "my_histogram.Stddev" => 29.4}}

# Remove a histogram
iex> Metrics.Histogram.remove "my_histogram"
:ok

```

## Benchmark

The benchmarks were performed on a MacBook Pro (13 Zoll, Mid 2012), with 8 GB 1600 MHz DDR3 RAM. You can repeat them with

```
git clone https://github.com/fourcube/exmetrics.git; cd exmetrics
mix deps.get
mix bench
```

#### Results
```
## Exmetrics.Bench
Exmetrics.record/2                        1000000   1.21 µs/op
Exmetrics.Counter.incr/1                  1000000   1.37 µs/op
Exmetrics.Counter.add/2                   1000000   1.50 µs/op
Exmetrics.Gauge.set/2                     1000000   1.57 µs/op
Exmetrics.Counter.get/1                    500000   5.70 µs/op
Exmetrics.Gauge.get/1                      500000   6.03 µs/op
Exmetrics.snapshot/0 - 1 histogram          20000   102.50 µs/op
Exmetrics.Histogram.new/3                   10000   358.51 µs/op
Exmetrics.snapshot/0 - 10 histograms         1000   1033.07 µs/op
Exmetrics.snapshot/0 - 100 histograms         100   10444.18 µs/op
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add exmetrics and hdr_histogram to your list of dependencies in `mix.exs`:

        def deps do
          [
            {:metrics, "~> 1.0"},
            {:hdr_histogram, git: "https://github.com/HdrHistogram/hdr_histogram_erl.git", tag: "0.2.6"}
          ]
        end

  2. Ensure exmetrics is started before your application:

        def application do
          [applications: [:exmetrics]]
        end
