defmodule Ciroque.Monitoring.RetrieveFunctionDurationArgs do
  @moduledoc false

  @type t :: %__MODULE__{
    module: String.t,
    function: String.t
  }

  defstruct [
    :module,
    :function
  ]
end
