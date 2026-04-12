defmodule JidoBuilderRuntime.BareAgentRoutesTest do
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.BareAgent
  alias JidoBuilderRuntime.Actions.{Echo, IncrementCounter, LogMessage, TransformData}

  test "bare agent exposes route table" do
    routes = BareAgent.signal_routes(%{})

    assert routes["ping"] == Echo
    assert routes["increment"] == IncrementCounter
    assert routes["transform"] == TransformData
    assert routes["log"] == LogMessage
  end

  test "route_for returns not_found for missing route" do
    assert {:error, %{code: :no_route}} = BareAgent.route_for("unknown")
  end
end
