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

defmodule Ciroque.Monitoring.StatsAgg.Profiler do
  @moduledoc false

  alias Ciroque.Monitoring.StatsAgg

  import ExProf.Macro

  def exprof_profile() do
    profile do
      run()
    end
  end

  def fprof_profile() do
    :fprof.apply(&run/0, [])
    :fprof.profile()
    :fprof.analyse(
      [
        callers: true,
        sort: :own,
        totals: true,
        details: true
      ]
    )
  end

  def run() do
    {:ok, _stats_agg} = StatsAgg.start_link()

    arguments = [
      %{group: "group_one", module: "module_one", function: "fx/1", duration: 100},
      %{group: "group_one", module: "module_one", function: "fx/2", duration: 100},
      %{group: "group_one", module: "module_two", function: "fx/3", duration: 100},
      %{group: "group_one", module: "module_two", function: "fx/4", duration: 100},
      %{group: "group_one", module: "module_three", function: "fx/5", duration: 100},
      %{group: "group_one", module: "module_three", function: "fx/0", duration: 100},
      %{group: "group_one", module: "module_four", function: "fx/1", duration: 100},
      %{group: "group_one", module: "module_four", function: "fx/2", duration: 100},
      %{group: "group_one", module: "module_four", function: "fx/3", duration: 100},
      %{group: "group_one", module: "module_five", function: "fx/5", duration: 100},
    ]

    divisor = length(arguments)

    1..1_000_000
    |> Enum.map(
      fn index ->
        args = arguments |> Enum.at(rem index, divisor)
        StatsAgg.record_function_duration(args)
      end)
  end
end
