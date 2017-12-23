defmodule Ciroque.Monitoring.StatsAggTest do
  use ExUnit.Case

  alias Ciroque.Monitoring.StatsAgg
  doctest StatsAgg

  defp empty_state, do: %{}

  defp function_duration_args do %{
      module: __MODULE__,
      function: "test/0",
      duration: 1000
    }
  end

  setup do
    {:ok, pid} = StatsAgg.start_link()
    %{server: pid}
  end

  test "start link with initial state" do
    {:ok, pid} = StatsAgg.start_link(empty_state())
    assert pid != nil
  end

  test "handles record function duration cast", %{server: server} do
    :ok = GenServer.cast(server, {:record_function_duration, function_duration_args()})
    new_state = :sys.get_state(server)
    assert new_state == empty_state()
  end

  test "record_function_duration public api", %{server: server} do
    StatsAgg.record_function_duration(server, function_duration_args())
    new_state = :sys.get_state(server)
    assert new_state == empty_state()
  end
end
