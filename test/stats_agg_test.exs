_ = """
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

defmodule Ciroque.Monitoring.StatsAggTest do
  use Ciroque.Monitoring.GenServerCase

  alias Ciroque.Monitoring.StatsAgg
  doctest StatsAgg

  defp function_duration_args do %{
      group: :test,
      module: __MODULE__,
      function: "test/0",
      duration: 1000
    }
  end

  defp nonexistant_function_stats_args do
    [
      "test",
       "#{__MODULE__}",
      "nonexistant/0"
    ]
  end

  defp expected_state do
    %{"test" => %{"Elixir.Ciroque.Monitoring.StatsAggTest" => %{"test/0" => [1000]}}}
  end

  setup do
    {:ok, pid} = StatsAgg.start_link()
    %{server: pid}
  end

  test "handles record function duration cast" do
    :ok = GenServer.cast(:ex_stats_agg, {:record_function_duration, function_duration_args()})
    assert_cast_state(:ex_stats_agg, expected_state())
  end

  test "record_function_duration public api" do
    StatsAgg.record_function_duration(function_duration_args())
    assert_cast_state(:ex_stats_agg, expected_state())
  end

  test "retrieve empty function duration info" do
    :notfound = GenServer.call(:ex_stats_agg, {:retrieve_stats, nonexistant_function_stats_args()})
  end

  test "retrieve_stats public api" do
    :notfound = StatsAgg.retrieve_stats(nonexistant_function_stats_args())
  end

  test "record durations using timestamps" do
    ended_at = :os.system_time(:millisecond)
    duration = 3 * 1000 # 3 seconds
    started_at = ended_at - duration
    args = %{group: "test-group", module: "test-module", function: "function/0", started_at: started_at, ended_at: ended_at}
    expected_stats = %{
      avg_duration: duration,
      durations: [duration],
      function: "function/0",
      group: "test-group",
      max_duration: duration,
      min_duration: duration,
      module: "test-module",
      most_recent_duration: duration
    }

    StatsAgg.record_function_duration(args)

    _ = :sys.get_state(:ex_stats_agg)

    actual_stats = StatsAgg.retrieve_stats(["test-group", "test-module", "function/0"])
    assert actual_stats === expected_stats
  end

  test "record durations for a single function and get the stats" do
    update_args_one = %{group: "test-group", module: "test-module", function: "test-function/0", duration: 100}
    update_args_two = %{group: "test-group", module: "test-module", function: "test-function/0", duration: 200}
    update_args_three = %{group: "test-group", module: "test-module", function: "test-function/0", duration: 300}

    query = ["test-group", "test-module", "test-function/0"]

    expected_stats = %{
      avg_duration: 200,
      durations: [300, 200, 100],
      function: "test-function/0",
      group: "test-group",
      max_duration: 300,
      min_duration: 100,
      module: "test-module",
      most_recent_duration: 300
    }

    StatsAgg.record_function_duration(update_args_one)
    StatsAgg.record_function_duration(update_args_two)
    StatsAgg.record_function_duration(update_args_three)

    _ = :sys.get_state(:ex_stats_agg)

    actual_stats = StatsAgg.retrieve_stats(query)

    assert actual_stats === expected_stats
  end

  test "write durations for a multiple functions and get the stats" do
    update_args_one = %{group: "test-group", module: "test-module", function: "test-function/0", duration: 100}
    update_args_two = %{group: "test-group", module: "test-module", function: "test-function/0", duration: 200}
    update_args_three = %{group: "test-group", module: "test-module", function: "test-function/0", duration: 300}

    update_args_four = %{group: "test-group-two", module: "test-module-two", function: "test-function/2", duration: 700}
    update_args_five = %{group: "test-group-two", module: "test-module-two", function: "test-function/2", duration: 800}
    update_args_six = %{group: "test-group-three", module: "test-module-three", function: "test-function/3", duration: 900}

    query = ["test-group-two", "test-module-two", "test-function/2"]

    expected_stats = %{
      avg_duration: 750,
      durations: [800, 700],
      function: "test-function/2",
      group: "test-group-two",
      max_duration: 800,
      min_duration: 700,
      module: "test-module-two",
      most_recent_duration: 800
    }

    StatsAgg.record_function_duration(update_args_one)
    StatsAgg.record_function_duration(update_args_two)
    StatsAgg.record_function_duration(update_args_three)
    StatsAgg.record_function_duration(update_args_four)
    StatsAgg.record_function_duration(update_args_five)
    StatsAgg.record_function_duration(update_args_six)

    _ = :sys.get_state(:ex_stats_agg)

    actual_stats = StatsAgg.retrieve_stats(query)

    assert actual_stats === expected_stats
  end
end
