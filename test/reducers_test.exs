defmodule ReducersTest do
  @moduledoc false

  use ExUnit.Case

  alias Ciroque.Monitoring.Reducers

  test "retrieve_stats for group" do

    durations = %{
      "group-one" => %{
        "module-one" => %{
          "function/0" => [1000, 1100]
        }
      },
      "group-two" => %{
        "module-one" => %{
          "function/2" => [130, 120]
        },
        "module-two" => %{
          "function/3" => [140]
        }
      },
      "group-three" => %{
        "module-two" => %{
          "function/4" => [330]
        }
      }
    }

    query = ["group-two"]
    expected_state = [
      %{
        avg_duration: 125,
        durations: [130, 120],
        function: "function/2",
        group: "group-two",
        max_duration: 130,
        min_duration: 120,
        module: "module-one",
        most_recent_duration: 130
      },
      %{
        avg_duration: 140,
        durations: [140],
        function: "function/3",
        group: "group-two",
        max_duration: 140,
        min_duration: 140,
        module: "module-two",
        most_recent_duration: 140
      }
    ]

    actual_state = Reducers.retrieve_stats(durations, query)

    assert actual_state === expected_state
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

    actual_state = Reducers.update_state(initial_state, update_args_one)
    actual_state = Reducers.update_state(actual_state, update_args_two)
    actual_state = Reducers.update_state(actual_state, update_args_three)
    actual_state = Reducers.update_state(actual_state, update_args_four)

    assert actual_state === expected_state
  end

  test "update_state with same key" do
    initial_state = %{}
    update_args = %{group: "test", module: "#{__MODULE__}", function: "function/0", duration: 500}
    expected_state = %{"test" => %{"#{__MODULE__}" => %{ "function/0" => [500, 500, 500, 500] }}}
    actual_state = Reducers.update_state(initial_state, update_args)
    actual_state = Reducers.update_state(actual_state, update_args)
    actual_state = Reducers.update_state(actual_state, update_args)
    actual_state = Reducers.update_state(actual_state, update_args)
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

    actual_stats = Reducers.calculate_stats(durations)

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

    actual_stats = Reducers.calculate_stats(durations)

    assert actual_stats === expected_stats
  end

  test "update_state with new keys" do
    initial_state = %{}
    update_args = %{group: "test", module: "#{__MODULE__}", function: "function/0", duration: 500}
    expected_state = %{"test" => %{"#{__MODULE__}" => %{ "function/0" => [500] }}}
    actual_state = Reducers.update_state(initial_state, update_args)
    assert actual_state === expected_state
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

    actual_stats = Reducers.calculate_stats(durations)

    assert actual_stats === expected_stats
  end
end
