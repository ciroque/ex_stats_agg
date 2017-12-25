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

  def record_function_duration(server, %{group: _group, module: _module, function: _function, duration: _duration} = args) do
    GenServer.cast(server, {:record_function_duration, args})
  end

  def retrieve_function_stats(server, %{module: _module, function: _function} = args) do
    GenServer.call(server, {:retrieve_function_stats, args})
  end

  ## GenServer

  def start_link() do
    start_link(%{})
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
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

  def handle_call({:retrieve_function_stats, %{group: group, module: module, function: function}}, _from, state) do
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
end
