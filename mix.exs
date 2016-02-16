defmodule Metrics.Mixfile do
  use Mix.Project

  def project do
    [app: :exmetrics,
     version: "0.2.1",
     name: "exmetrics",
     description: "Exmetrics provides counters, gauges and histograms for instrumenting an elixir application.",
     elixir: "~> 1.2-rc",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/fourcube/exmetrics",
     deps: deps,
     package: [
       files: ["lib", "mix.exs", "README*", "LICENSE*"],
       licenses: ["MIT"],
       maintainers: ["Chris Grieger"]
     ],
     docs: [extras: ["README.md"]]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :hdr_histogram],
     mod: {Exmetrics, []}]
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
