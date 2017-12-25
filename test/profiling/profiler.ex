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
