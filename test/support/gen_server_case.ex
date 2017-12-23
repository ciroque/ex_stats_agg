defmodule Ciroque.Monitoring.GenServerCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      import Ciroque.Monitoring.GenServerCase
    end
  end

  def assert_cast_state(pid, expected_state) do
    actual_state = :sys.get_state(pid)
    assert actual_state == expected_state
  end
end
