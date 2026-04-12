defmodule JidoBuilderRuntime.StatePubSubTest do
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.EventBus

  test "agent_state_topic builds scoped topic name" do
    assert EventBus.agent_state_topic(2, "agent-a") == "workspace:2:agent:agent-a:state"
  end
end
