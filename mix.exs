defmodule StatsAgg.Mixfile do
  use Mix.Project

  def project do
    [
      app: :stats_agg,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "test/profiling", "lib"]
  defp elixirc_paths(_),     do: ["lib", "test/profiling"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exprof, "~> 0.2.1"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
