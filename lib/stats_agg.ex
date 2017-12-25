defmodule Ciroque.Monitoring.StatsAgg do
  @moduledoc """
  Documentation for StatsAgg.


  %{
    group: String.t,
    module: String.t,
    function: String.t,
    most_recent_duration: integer,
    max_duration: integer,
    min_duration: integer,
    avg_duration: integer,
    duration_history: list(integer)
  }

  """

  use GenServer

  require Logger

  ## Public Interface

  def record_function_duration(%{group: _group, module: _module, function: _function, duration: _duration} = args) do
    GenServer.cast(:ex_stats_agg, {:record_function_duration, args})
  end

  def retrieve_stats(%{group: _group} = query) do
    GenServer.call(:ex_stats_agg, {:retrieve_stats, query})
  end

  def retrieve_stats(%{group: _group, module: _module, function: _function} = query) do
    GenServer.call(:ex_stats_agg, {:retrieve_stats, query})
  end

  ## GenServer

  def start_link() do
    start_link(%{})
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: :ex_stats_agg)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({
    :record_function_duration,
    %{
      group: _group,
      module: _module,
      function: _function,
      duration: _duration} = args
    }, state) do

    {:noreply, update_state(state, args)}
  end

  def handle_call({:retrieve_stats, %{group: group, module: module, function: function}}, _from, state) do
    keys = [
      to_string(group),
      to_string(module),
      to_string(function)
    ]

    case state |> get_in(keys) do
      nil ->
        {:reply, :notfound, state}
      durations ->
        function_stats = Map.merge(
          calculate_stats(durations),
          %{
            group: group,
            module: module,
            function: function
          }
        )
        {:reply, function_stats, state}
    end
  end

  def handle_call({:retrieve_stats, %{group: _group}}, _from, state) do
    {:reply, %{}, state}
  end

  def calculate_stats(durations) do
    %{
      avg_duration: div(Enum.sum(durations), length(durations)),
      durations: durations,
      max_duration: Enum.max(durations),
      min_duration: Enum.min(durations),
      most_recent_duration: List.first(durations),
    }
  end

  def update_state(state, %{group: group, module: module, function: function, duration: duration}) do
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

  def build_flattened_map(state, []) do
    Map.keys(state)
    |> Enum.map(fn key -> build_flattened_map(state, [key]) end)
    |> List.flatten
  end

  def build_flattened_map(state, [_|_] = keys) do
    stats = case state |> get_in(keys) do
      nil -> []
      children ->
        process_children(state, keys, children)
    end
    stats
  end

  defp process_children(_state, keys, children) when is_list(children) do
    output_keys = [:group, :module, :function, :durations]
    List.zip([output_keys, keys ++ [children]])
    |> Enum.into(%{})
  end

  defp process_children(state, keys, children) when is_map(children) do
    children
    |> Map.keys
    |> Enum.map(fn key ->
      new_keys = keys ++ [key]
      build_flattened_map(state, new_keys)
    end)
    |> List.flatten
  end
end
