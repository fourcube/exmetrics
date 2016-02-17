defmodule Exmetrics.Bench do
  use Benchfella
  require Logger

  setup_all do
    Application.ensure_all_started(:exmetrics)
  end

  teardown_all _ do
    Application.stop(:exmetrics)
  end

  after_each_bench _ do
    Exmetrics.reset
  end

  bench "Exmetrics.Gauge.set/2" do
    Exmetrics.Gauge.set "foo", 1
  end

  bench "Exmetrics.Gauge.get/1" do
    Exmetrics.Gauge.get "foo"
  end

  bench "Exmetrics.Histogram.new/3" do
    Exmetrics.Histogram.new "foo", 1000000, 3
  end

  bench "Exmetrics.snapshot/0 - 1 histogram", [unused: new_histogram(1)] do
    Exmetrics.snapshot
  end

  bench "Exmetrics.snapshot/0 - 10 histograms", [unused: new_histogram(10)] do
    Exmetrics.snapshot
  end

  bench "Exmetrics.snapshot/0 - 100 histograms", [unused: new_histogram(100)] do
    Exmetrics.snapshot
  end

  bench "Exmetrics.record/2", [unused: new_histogram(0)] do
    Exmetrics.Histogram.record "foo0", 10000
  end

  bench "Exmetrics.Counter.incr/1" do
    Exmetrics.Counter.incr "foo"
  end

  bench "Exmetrics.Counter.add/2" do
    Exmetrics.Counter.add "foo", 42
  end

  bench "Exmetrics.Counter.get/1", [unused: Exmetrics.Counter.incr "foo"] do
    Exmetrics.Counter.get "foo"
  end

  def new_histogram(n) do
    Enum.each 0..(n-1), &(Exmetrics.Histogram.new "foo#{&1}", 1000000, 3)
  end


end
