defmodule Ciroque.Monitoring.StatsAggTest do
  use Ciroque.Monitoring.GenServerCase

  alias Ciroque.Monitoring.StatsAgg
  doctest StatsAgg

  defp empty_state, do: %{}

  defp function_duration_args do %{
      group: :test,
      module: __MODULE__,
      function: "test/0",
      duration: 1000
    }
  end

  defp nonexistant_function_stats_args do
    %{
      group: :test,
      module: __MODULE__,
      function: "nonexistant/0"
    }
  end

  defp expected_state do
    %{"test" => %{"Elixir.Ciroque.Monitoring.StatsAggTest" => %{"test/0" => [1000]}}}
  end

  setup do
    {:ok, pid} = StatsAgg.start_link()
    %{server: pid}
  end

  test "start link with initial state" do
    {:ok, pid} = StatsAgg.start_link(empty_state())
    assert pid != nil
  end

  test "handles record function duration cast", %{server: server} do
    :ok = GenServer.cast(server, {:record_function_duration, function_duration_args()})
    assert_cast_state(server, expected_state())
  end

  test "record_function_duration public api", %{server: server} do
    StatsAgg.record_function_duration(server, function_duration_args())
    assert_cast_state(server, expected_state())
  end

  test "retrieve empty function duration info", %{server: server} do
    :notfound = GenServer.call(server, {:retrieve_function_stats, nonexistant_function_stats_args()})
  end

  test "retrieve_function_stats public api", %{server: server} do
    :notfound = StatsAgg.retrieve_function_stats(server, nonexistant_function_stats_args())
  end

  test "update_state with new keys" do
    initial_state = %{}
    update_args = %{group: "test", module: "#{__MODULE__}", function: "function/0", duration: 500}
    expected_state = %{"test" => %{"#{__MODULE__}" => %{ "function/0" => [500] }}}
    actual_state = StatsAgg.update_state(initial_state, update_args)
    assert actual_state === expected_state
  end

  test "update_state with same key" do
    initial_state = %{}
    update_args = %{group: "test", module: "#{__MODULE__}", function: "function/0", duration: 500}
    expected_state = %{"test" => %{"#{__MODULE__}" => %{ "function/0" => [500, 500, 500, 500] }}}
    actual_state = StatsAgg.update_state(initial_state, update_args)
    actual_state = StatsAgg.update_state(actual_state, update_args)
    actual_state = StatsAgg.update_state(actual_state, update_args)
    actual_state = StatsAgg.update_state(actual_state, update_args)
    assert actual_state === expected_state
  end

  test "write durations for a single function and get the stats", %{server: server} do
    update_args_one = %{group: "test-group", module: "test-module", function: "test-function/0", duration: 100}
    update_args_two = %{group: "test-group", module: "test-module", function: "test-function/0", duration: 200}
    update_args_three = %{group: "test-group", module: "test-module", function: "test-function/0", duration: 300}

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

    StatsAgg.record_function_duration(server, update_args_one)
    StatsAgg.record_function_duration(server, update_args_two)
    StatsAgg.record_function_duration(server, update_args_three)

    _ = :sys.get_state(server)

    actual_stats = StatsAgg.retrieve_function_stats(server, update_args_one)

    assert actual_stats === expected_stats
  end

  test "write durations for a multiple functions and get the stats", %{server: server} do
    update_args_one = %{group: "test-group", module: "test-module", function: "test-function/0", duration: 100}
    update_args_two = %{group: "test-group", module: "test-module", function: "test-function/0", duration: 200}
    update_args_three = %{group: "test-group", module: "test-module", function: "test-function/0", duration: 300}

    update_args_four = %{group: "test-group-two", module: "test-module-two", function: "test-function/2", duration: 700}
    update_args_five = %{group: "test-group-two", module: "test-module-two", function: "test-function/2", duration: 800}
    update_args_six = %{group: "test-group-three", module: "test-module-three", function: "test-function/3", duration: 900}

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

    StatsAgg.record_function_duration(server, update_args_one)
    StatsAgg.record_function_duration(server, update_args_two)
    StatsAgg.record_function_duration(server, update_args_three)
    StatsAgg.record_function_duration(server, update_args_four)
    StatsAgg.record_function_duration(server, update_args_five)
    StatsAgg.record_function_duration(server, update_args_six)

    _ = :sys.get_state(server)

    actual_stats = StatsAgg.retrieve_function_stats(server, update_args_four)

    assert actual_stats === expected_stats
  end

  test "multiple keys" do
    initial_state = %{}

    update_args_one = %{group: "test", module: "#{__MODULE__}", function: "first/0", duration: 100}
    update_args_two = %{group: "test", module: "#{__MODULE__}", function: "second/0", duration: 200}
    update_args_three = %{group: "test", module: "#{__MODULE__}", function: "third/0", duration: 300}
    update_args_four = %{group: "test", module: "#{__MODULE__}", function: "first/0", duration: 500}

    expected_state = %{
      "test" => %{
        "#{__MODULE__}" => %{
          "first/0" => [500, 100],
          "second/0" => [200],
          "third/0" => [300]
        }
      }
    }

    actual_state = StatsAgg.update_state(initial_state, update_args_one)
    actual_state = StatsAgg.update_state(actual_state, update_args_two)
    actual_state = StatsAgg.update_state(actual_state, update_args_three)
    actual_state = StatsAgg.update_state(actual_state, update_args_four)

    assert actual_state === expected_state
  end

  test "calculate_stats with one recorded duration" do
    durations = [1000]
    expected_stats = %{
      most_recent_duration: 1000,
      max_duration: 1000,
      min_duration: 1000,
      avg_duration: 1000,
      durations: [1000]
    }

    actual_stats = StatsAgg.calculate_stats(durations)

    assert actual_stats === expected_stats
  end

  test "calculate_stats with many recorded durations" do
    durations = [1000, 500, 750]
    expected_stats = %{
      most_recent_duration: 1000,
      max_duration: 1000,
      min_duration: 500,
      avg_duration: 750,
      durations: [1000, 500, 750]
    }

    actual_stats = StatsAgg.calculate_stats(durations)

    assert actual_stats === expected_stats
  end

  test "calculate_stats with 100 recorded durations" do
    durations = Enum.to_list(1..100)
    expected_stats = %{
      most_recent_duration: 1,
      max_duration: 100,
      min_duration: 1,
      avg_duration: 50,
      durations: durations
    }

    actual_stats = StatsAgg.calculate_stats(durations)

    assert actual_stats === expected_stats
  end
end
