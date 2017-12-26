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

defmodule Ciroque.Monitoring.Reducers do
  @moduledoc """
    This module contains the functions necessary to maintain the data structure
    used by the `Ciroque.Monitoring.StatsAgg` module.

    This module is not intended for direct use outside of the context of the StatsAgg module.
  """

  @doc """
  Calculates various statistics on the given array of execution durations.

  Included are:
      - Average
      - Max
      - Min

    The return is a map containing the original array of durations, the above statistics and the most recent duration.

    Note: While this can be used outside of the StatsAgg module, it is not intended for direct use
    outside of the Context of the StatsAgg module.
  """
  def calculate_stats(durations) do
    %{
      avg_duration: div(Enum.sum(durations), length(durations)),
      durations: durations,
      max_duration: Enum.max(durations),
      min_duration: Enum.min(durations),
      most_recent_duration: List.first(durations),
    }
  end

  @doc """
  Records the given duration into the state. In this case the given `started_at` and `ended_at` values are used to
  caluclate the duration.

  Note: While this can be used outside of the StatsAgg module, it is not intended for direct use
  outside of the Context of the StatsAgg module.
  """
  def put_duration(state, %{group: _group, module: _module, function: _function, started_at: started_at, ended_at: ended_at} = args) do
    duration = ended_at - started_at
    args = args
    |> Map.drop([:started_at, :ended_at])
    |> Map.put_new(:duration, duration)

    put_duration(state, args)
  end

  @doc """
  Calculates and returns the stats for the given keys in the given state.

  The shape of the data returned:

    ```
    %{
      avg_duration: integer,
      durations: list(integer),
      function: String.t,
      group: String.t,
      max_duration: integer,
      min_duration: integer,
      module: String.t,
      most_recent_duration: integer,
    }
    ```

  Note: While this can be used outside of the StatsAgg module, it is not intended for direct use
  outside of the Context of the StatsAgg module.
  """
  def retrieve_stats(state, keys) do
    flatten_entries(state, keys)
    |> with_stats
  end

  @doc """
  Records the given duration into the state.

  Note: While this can be used outside of the StatsAgg module, it is not intended for direct use
  outside of the Context of the StatsAgg module.
  """
  def put_duration(state, %{group: group, module: module, function: function, duration: duration}) do
    keys = [
      to_string(group),
      to_string(module),
      to_string(function)
    ]
    case get_in(state, keys) do
      nil ->
        put_in(state, Enum.map(keys, &Access.key(&1, %{})), [duration])
      _ ->
        {_, new_state} = get_and_update_in(state, keys, fn v -> {v, [duration | v]} end)
        new_state
    end
  end

  defp flatten_entries(state, []) do
    Map.keys(state)
    |> Enum.map(fn key -> flatten_entries(state, [key]) end)
    |> List.flatten
  end

  defp flatten_entries(state, [_|_] = keys) do
    stats = case state |> get_in(keys) do
      nil -> []
      children ->
        process_child_keys(state, keys, children)
    end
    stats
  end

  defp process_child_keys(_state, keys, children) when is_list(children) do
    output_keys = [:group, :module, :function, :durations]
    List.zip([output_keys, keys ++ [children]])
    |> Enum.into(%{})
  end

  defp process_child_keys(state, keys, children) when is_map(children) do
    children
    |> Map.keys
    |> Enum.map(fn key ->
      new_keys = keys ++ [key]
      flatten_entries(state, new_keys)
    end)
    |> List.flatten
  end

  defp with_stats(method_entries) when is_list(method_entries) do
    method_entries
    |> Enum.map(fn entry ->
      Map.merge(
        calculate_stats(entry.durations),
        entry
      )
    end)
  end

  defp with_stats(method_entries) when is_map(method_entries) do
    Map.merge(
      calculate_stats(method_entries.durations),
      method_entries
    )
  end
end
