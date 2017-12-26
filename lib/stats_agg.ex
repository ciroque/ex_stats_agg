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

  alias Ciroque.Monitoring.Reducers

  require Logger

  use GenServer

  ## Public Interface

  def record_function_duration(%{group: _group, module: _module, function: _function, duration: _duration} = args) do
    GenServer.cast(:ex_stats_agg, {:record_function_duration, args})
  end

  def retrieve_stats(query) when is_list(query) do
    GenServer.call(:ex_stats_agg, {:retrieve_stats, query})
  end

  ## GenServer

  def handle_call({:retrieve_stats, keys}, _from, state) when is_list(keys) do
    case Reducers.retrieve_stats(state, keys) do
      [] -> {:reply, :notfound, state}
      function_stats -> {:reply, function_stats, state}
    end
  end

  def handle_cast({
    :record_function_duration,
    %{
      group: _group,
      module: _module,
      function: _function,
      duration: _duration} = args
  }, state) do

    {:noreply, Reducers.update_state(state, args)}
  end

  def init(state) do
    {:ok, state}
  end

  def start_link() do
    start_link(%{})
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: :ex_stats_agg)
  end
end
