"""
MIT License

Copyright (c) 2017 Steven Wagner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

defmodule StatsAgg.Mixfile do
  use Mix.Project

  def project do
    [
      app: :stats_agg,
      version: "0.1.3",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: description(),
      name: "stats_agg",
      package: package()
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
      {:exprof, "~> 0.2.1"},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end

  defp description() do
    "StatsAgg is a library that allows the developer to instrument functions so that execution times are logged.
      Stats can then be retrieved and used to populate dashboards and other Information Radiators."
  end

  defp package() do
    [
      name: "ex_stats_agg",
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Steve Wagner"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ciroque/ex_stats_agg"}
    ]
  end
end
