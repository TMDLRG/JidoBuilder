defmodule JidoBuilderRuntime.BareAgentRoutesTest do
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.BareAgent
  alias JidoBuilderRuntime.Actions.{Echo, IncrementCounter, LogMessage, TransformData}

  test "bare agent exposes route table as list of tuples" do
    routes = BareAgent.signal_routes(%{})

    assert Enum.any?(routes, fn {p, m} -> p == "ping" and m == Echo end)
    assert Enum.any?(routes, fn {p, m} -> p == "increment" and m == IncrementCounter end)
    assert Enum.any?(routes, fn {p, m} -> p == "transform" and m == TransformData end)
    assert Enum.any?(routes, fn {p, m} -> p == "log" and m == LogMessage end)
  end

  test "route_for returns not_found for missing route" do
    assert {:error, %{code: :no_route}} = BareAgent.route_for("unknown")
  end
end
