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

defmodule ReducersTest do
  @moduledoc false

  use ExUnit.Case

  alias Ciroque.Monitoring.Reducers

  describe "calculate_stats" do
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

  describe "put_duration" do
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

      actual_state = Reducers.put_duration(initial_state, update_args_one)
      actual_state = Reducers.put_duration(actual_state, update_args_two)
      actual_state = Reducers.put_duration(actual_state, update_args_three)
      actual_state = Reducers.put_duration(actual_state, update_args_four)

      assert actual_state === expected_state
    end

    test "same key" do
      initial_state = %{}
      update_args = %{group: "test", module: "#{__MODULE__}", function: "function/0", duration: 500}
      expected_state = %{"test" => %{"#{__MODULE__}" => %{ "function/0" => [500, 500, 500, 500] }}}
      actual_state = Reducers.put_duration(initial_state, update_args)
      actual_state = Reducers.put_duration(actual_state, update_args)
      actual_state = Reducers.put_duration(actual_state, update_args)
      actual_state = Reducers.put_duration(actual_state, update_args)
      assert actual_state === expected_state
    end

    test "new keys" do
      initial_state = %{}
      update_args = %{group: "test", module: "#{__MODULE__}", function: "function/0", duration: 500}
      expected_state = %{"test" => %{"#{__MODULE__}" => %{ "function/0" => [500] }}}
      actual_state = Reducers.put_duration(initial_state, update_args)
      assert actual_state === expected_state
    end

    test "using started_at and ended_at" do
      initial_state = %{}
      ended_at = :os.system_time(:millisecond)
      started_at = ended_at - 2 * 1_000 # 2 seconds
      update_args = %{group: "test", module: "#{__MODULE__}", function: "function/0", started_at: started_at, ended_at: ended_at }
      expected_state = %{"test" => %{"#{__MODULE__}" => %{"function/0" => [2000]}}}
      actual_state = Reducers.put_duration(initial_state, update_args)
      assert actual_state === expected_state
    end
  end

  describe "retrieve_stats" do
    test "for group" do
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
  end
end
