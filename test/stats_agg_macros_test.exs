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
      1..100_000
      |> Enum.map(fn index ->
        {:ok, %{index: index, mapped: rem(index, 10)}}
      end)
    end
  end

  defp instrumented_function_with_default_group() do
    with_stats_agg() do
      1..100_000
      |> Enum.map(fn index ->
        {:ok, %{index: index, mapped: rem(index, 10)}}
      end)
    end
  end
end
