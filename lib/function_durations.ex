defmodule Ciroque.Monitoring.FunctionDurations do
  @moduledoc false

  @type t :: %__MODULE__{
    module: String.t,
    function: String.t,
    most_recent_duration: integer,
    max_duration: integer,
    min_duration: integer,
    avg_duration: integer,
    duration_history: list(integer)
  }

  defstruct [
    :module,
    :function,
    :most_recent_duration,
    :max_duration,
    :min_duration,
    :avg_duration,
    duration_history: []
  ]
end
