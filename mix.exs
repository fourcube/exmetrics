defmodule Metrics.Mixfile do
  use Mix.Project

  def project do
    [app: :metrics,
     version: "0.1.1",
     name: "metrics",
     description: "metrics provides counters, gauges and histograms for instrumenting an elixir application."
     elixir: "~> 1.2-rc",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/fourcube/metrics",
     deps: deps,
     licenses: ["MIT"],
     docs: [extras: ["README.md"]]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],
     mod: {Metrics, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:hdr_histogram, git: "https://github.com/HdrHistogram/hdr_histogram_erl.git", tag: "0.2.6"},

      # Development only
      {:markdown, github: "devinus/markdown"},
      {:dialyxir, "~> 0.3", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end
end
