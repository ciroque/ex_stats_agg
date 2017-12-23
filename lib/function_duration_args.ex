defmodule Ciroque.Monitoring.FunctionDurationArgs do
  @moduledoc false

  @type t :: %__MODULE__{
    module: String.t,
    function: String.t,
    duration: integer
  }

  defstruct [
    :module,
    :function,
    :duration
  ]
end
