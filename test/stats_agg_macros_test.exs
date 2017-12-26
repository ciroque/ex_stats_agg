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

defmodule StatsAggMacrosTest do
  @moduledoc false

  require Logger

  alias Ciroque.Monitoring.StatsAgg

  use ExUnit.Case
  use Ciroque.Monitoring.StatsAggMacros

  @group_name "TESTING-1-2-3"

  setup do
    {:ok, pid} = StatsAgg.start_link()
    %{server: pid}
  end

  test "can instrument with macro" do
    instrumented_function()
    _ = :sys.get_state(:ex_stats_agg)
    actual_stats = StatsAgg.retrieve_stats([])

    assert length(actual_stats) === 1
  end

  test "multiple invocations are recorded" do
    expected_count = 3
    for _ <- 1..expected_count, do: instrumented_function()
    _ = :sys.get_state(:ex_stats_agg)
    actual_stats = StatsAgg.retrieve_stats([@group_name])
    assert length(List.first(actual_stats).durations) === expected_count
  end

  test "using default group" do
    expected_count = 3
    for _ <- 1..expected_count, do: instrumented_function_with_default_group()
    _ = :sys.get_state(:ex_stats_agg)

    assert :notfound === StatsAgg.retrieve_stats([@group_name])

    actual_stats = StatsAgg.retrieve_stats(["main"])
    assert length(List.first(actual_stats).durations) === expected_count
  end

  defp instrumented_function() do
    with_stats_agg(@group_name) do
      for i <- 1..100_000, do: %{ index: i, mapped: rem(i, 10) }
    end
  end

  defp instrumented_function_with_default_group() do
    with_stats_agg() do
      for i <- 1..100_000, do: %{ index: i, mapped: rem(i, 10) }
    end
  end
end
