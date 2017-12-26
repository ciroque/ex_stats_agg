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

defmodule Ciroque.Monitoring.StatsAgg do
  @moduledoc """
  Records and calculates statistics for function execution durations.


  """

  alias Ciroque.Monitoring.Reducers

  require Logger

  use GenServer

  ## Public Interface

  @typedoc """
  Defines the maps that are acceptable to the record duration implementation.

  The duration version is straight forward.

  The `started_at` / `ended_at` version calculates the duration using the provided values. These values
  should be integers. `os:system_time(:millisecond)` is the intended -- and tested -- case, though
  `os:system_time(:microsecond)` should work.

  String formatted Date / Times are *_not_* supported at this time.
  """
  @type record_function_duration_args_t ::
          %{group: String.t, module: String.t, function: String.t, duration: integer}
          | %{group: String.t, module: String.t, function: String.t, started_at: integer, ended_at: integer}


  @doc """
  Stores the given duration.

  As noted in the `record_function_duration_args_t` section, there are two versions of this method.

  The first takes the duration.

  ## Example
  ```
  iex> args = %{ group: "MyGroup", module: "#{__MODULE__}", function: "function/0", duration: 1200 }
  %{ group: "MyGroup", module: "#{__MODULE__}", function: "function/0", duration: 1200 }
  iex> :ok = StatsAgg.record_function_duration(args)
  :ok
  ```

  The second takes the started_at and ended_at values as integers.

  ## Example
  ```
  iex> args = %{ group: "MyGroup", module: "#{__MODULE__}", function: "function/0", started_at: 1514331128740, ended_at: 1514331139316 }
  %{ group: "MyGroup", module: "#{__MODULE__}", function: "function/0", started_at: 1514331128740, ended_at: 1514331139316  }
  iex> :ok = StatsAgg.record_function_duration(args)
  :ok
  ```

  Returns: `:ok`

  The method is asychronous.
  """
  def record_function_duration(record_function_duration_args_t = args) do
    GenServer.cast(:ex_stats_agg, {:record_function_duration, args})
  end

  @doc """
  Retrieves the current snapshot of the stats that have been logged.

  The `query` paramater is a list of keys to be searched. The items are, in order,

  `group`, `module`, `function`.

  The returned value is a list of items with the following shape:

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

  ## Example
  ```
  iex>  args = %{ group: "MyGroup", module: "#{__MODULE__}", function: "function/0", duration: 1200 }
  %{ group: "MyGroup", module: "#{__MODULE__}", function: "function/0", duration: 1200 }
  iex> :ok = StatsAgg.record_function_duration(args)
  :ok
  iex>  query = ["MyGroup"]
  ["MyGroup"]
  iex>  StatsAgg.retrieve_stats(query)
  [%{avg_duration: 1200, durations: [1200], function: "function/0",
              group: "MyGroup", max_duration: 1200, min_duration: 1200,
              module: "Elixir.Ciroque.Monitoring.StatsAgg",
              most_recent_duration: 1200}]
  ```
  """
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

  def handle_cast({:record_function_duration, record_function_duration_args_t = args}, state) do
    {:noreply, Reducers.put_duration(state, args)}
  end

  def init(state) do
    {:ok, state}
  end

  @doc """
  Starts the StatsAgg process with the default state (an empty map, e.g. - `%{}`).
  """
  def start_link() do
    start_link(%{})
  end


  @doc """
  Starts the StatsAgg process with the provided state.
  """
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: :ex_stats_agg)
  end
end
