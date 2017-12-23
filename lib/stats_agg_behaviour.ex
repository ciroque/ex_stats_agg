defmodule Ciroque.Monitoring.StatsAggBehaviour do
  @moduledoc false

  alias Ciroque.Monitoring.FunctionDurationArgs
  alias Ciroque.Monitoring.FunctionDurations
  alias Ciroque.Monitoring.RetrieveFunctionDurationArgs

  @type pid_t :: pid
  @type function_duration_args_t :: FunctionDurationArgs.t
  @type function_durations_t :: list(FunctionDurations.t)
  @type retrieve_function_duration_args_t :: RetrieveFunctionDurationArgs

  @callback record_function_duration(pid_t, function_duration_args_t) :: :noreply
  @callback retrieve_function_stats(pid_t, retrieve_function_duration_args_t)
            :: {:ok, list(function_durations_t)}
            | {:notfound}
end
