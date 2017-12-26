defmodule Ciroque.Monitoring.StatsAggMacros do
  @moduledoc """
  This module contains macro definitions that make
  using the `Ciroque.Monitoring.StatsAgg` module easier.

  By including this module with: `use Ciroque.Monitoring.StatsAggMacros`
  in your modules you can instrument your functions like this:

  ## Example

    defmoule MyApp.MyModule do
      use Ciroque.Monitoring.StatsAggMacros

    end
  """

  @doc false
  defmacro __using__(_) do
    quote do
      import Ciroque.Monitoring.StatsAggMacros
    end
  end

  @doc """
  Returns a tuple containing the module name and the current function as strings.
  """
  defmacro module_function do
    quote do
      {function_name, arity} = __ENV__.function
      %{module: "#{__MODULE__}", function: "#{function_name}/#{arity}"}
    end
  end

  @doc """
  Allows easy use of the StatsAgg library
  to track function execution times.

    ## Example

    defmodule MyApp.MyModule do
      @group_name "MyGroup"

      alias Ciroque.Monitoring.StatsAgg

      require Logger

      use Ciroque.Monitoring.StatsAggMacros

      def my_function() do
        with_stats_agg(@group_name) do
          ## Your logic goes here...
          ...
        end
      end

      def log_stats() do
        stats = StatsAgg.retrieve_stats([@group_name])
        Logger.debug("StatsAgg statics for # {@group_name}: # {inspect(stats)}")
      end
    end

  Note that the `group` parameter can be used to associate entries. The idea is
  that by using groups it becomes easier to create groupings of StatsAgg stats
  for display on some manner of Information Radiator.

  Results of the `StatsAgg.retrieve_stats/1` function can be exposed via web endpoint to feed
  dashboards and the like.
  """
  defmacro with_stats_agg(group \\ "main", [do: block]) do
    quote do
      group = unquote(group)
      started_at = :os.system_time(:millisecond)
      result = unquote(block)
      ended_at = :os.system_time(:millisecond)

      module_function()
      |> Map.merge(%{group: group, started_at: started_at, ended_at: ended_at})
      |> Ciroque.Monitoring.StatsAgg.record_function_duration()

      result
    end
  end
end
