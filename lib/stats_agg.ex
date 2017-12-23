defmodule Ciroque.Monitoring.StatsAgg do
  @moduledoc """
  Documentation for StatsAgg.
  """

  @behaviour Ciroque.Monitoring.StatsAggBehaviour

  use GenServer

  require Logger

  ## Public Interface

  def record_function_duration(server, %{module: _module, function: _function, duration: _duration} = args) do
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

  def handle_cast({:record_function_duration, %{module: _module, function: _function, duration: _duration} = args}, state) do
    Logger.debug("#{__MODULE__}::#{inspect(__ENV__.function)}(#{inspect(args)})[#{inspect(state)}]")
    {:noreply, state}
  end

  def handle_call({:retrieve_function_stats, %{module: _module, function: _function}} = args, _from, state) do
    Logger.debug("#{__MODULE__}::#{inspect(__ENV__.function)}(#{inspect(args)})[#{inspect(state)}]")
    {:reply, :notfound, state}
  end
end
