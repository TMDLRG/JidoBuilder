defmodule JidoBuilderRuntime.EventBusCorrelationTest do
  use ExUnit.Case, async: false

  alias JidoBuilderRuntime.EventBus

  test "correlation_topic/2 returns correct topic string" do
    topic = EventBus.correlation_topic(1, "abc-123")
    assert topic == "workspace:1:correlation:abc-123"
  end

  test "async dispatch streams execution events via PubSub" do
    # Ensure PubSub is running
    if Process.whereis(JidoBuilder.PubSub) == nil do
      start_supervised!({Phoenix.PubSub, name: JidoBuilder.PubSub})
    end

    correlation_id = Ecto.UUID.generate()
    topic = EventBus.correlation_topic(1, correlation_id)

    # Subscribe to the correlation topic
    Phoenix.PubSub.subscribe(JidoBuilder.PubSub, topic)

    # Simulate what TelemetryBridge would publish
    event = %{
      kind: "signal",
      status: "stop",
      correlation_id: correlation_id,
      workspace_id: 1,
      measured_at: DateTime.utc_now(),
      duration_native: 42_000_000
    }

    Phoenix.PubSub.broadcast(JidoBuilder.PubSub, topic, {:jido_event, event})

    # Should receive the event
    assert_receive {:jido_event, received_event}, 1_000
    assert received_event.correlation_id == correlation_id
    assert received_event.kind == "signal"
  end
end
