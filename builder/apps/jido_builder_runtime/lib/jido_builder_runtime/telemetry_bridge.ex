defmodule JidoBuilderRuntime.TelemetryBridge do
  @moduledoc """
  Bridges Jido telemetry into Builder PubSub streams and persisted summaries.
  """

  use GenServer

  alias JidoBuilderCore.Observability
  alias JidoBuilderRuntime.{EventBus, Roster}

  @handler_id "jido-builder-runtime-telemetry-bridge"
  @actor "runtime.telemetry"

  @events [
    [:jido, :agent, :cmd, :start],
    [:jido, :agent, :cmd, :stop],
    [:jido, :agent, :cmd, :exception],
    [:jido, :agent_server, :signal, :start],
    [:jido, :agent_server, :signal, :stop],
    [:jido, :agent_server, :signal, :exception],
    [:jido, :agent_server, :directive, :start],
    [:jido, :agent_server, :directive, :stop],
    [:jido, :agent_server, :directive, :exception],
    [:jido, :action, :start],
    [:jido, :action, :stop],
    [:jido, :action, :exception]
  ]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :ok = :telemetry.attach_many(@handler_id, @events, &__MODULE__.handle_event/4, %{})
    {:ok, %{}}
  end

  @impl true
  def terminate(_reason, _state) do
    :telemetry.detach(@handler_id)
    :ok
  end

  def handle_event(event_name, measurements, metadata, _config) do
    event = normalize(event_name, measurements, metadata)
    workspace_id = event.workspace_id

    publish(event, EventBus.workspace_activity_topic(workspace_id))

    if event.agent_id do
      publish(event, EventBus.agent_topic(workspace_id, event.agent_id))
    end

    publish(event, EventBus.workflow_activity_topic(workspace_id))

    if event.workflow_id do
      publish(event, EventBus.workflow_topic(workspace_id, event.workflow_id))
    end

    persist(event)
    persist_error(event)
    publish_state_change(event)
  end

  defp normalize(event_name, measurements, metadata) do
    status = List.last(event_name)
    kind = Enum.at(event_name, 2)

    %{
      id: System.unique_integer([:positive, :monotonic]),
      kind: to_string(kind),
      status: to_string(status),
      event: event_name,
      event_name: Enum.map_join(event_name, ".", &to_string/1),
      measured_at: DateTime.utc_now(),
      workspace_id: pick_workspace_id(metadata),
      agent_id: pick_agent_id(metadata),
      workflow_id: Map.get(metadata, :workflow_id),
      correlation_id: Map.get(metadata, :jido_trace_id),
      duration_native: Map.get(measurements, :duration),
      measurements:
        Map.take(measurements, [:duration, :system_time, :directive_count, :queue_size]),
      metadata: scrub_metadata(metadata)
    }
  end

  defp publish(event, topic) do
    if Process.whereis(JidoBuilder.PubSub) do
      Phoenix.PubSub.broadcast(JidoBuilder.PubSub, topic, {:jido_event, event})
    end

    :ok
  end

  defp persist(%{kind: "signal"} = event) do
    attrs = %{
      workspace_id: event.workspace_id,
      agent_instance_id: maybe_integer(event.agent_id),
      direction: "runtime.telemetry",
      signal_type: event.metadata[:signal_type] || event.event_name,
      payload: persistence_payload(event),
      correlation_id: event.correlation_id
    }

    _ = Observability.log_signal(attrs, @actor)
    :ok
  end

  defp persist(%{kind: "directive"} = event) do
    attrs = %{
      workspace_id: event.workspace_id,
      agent_instance_id: maybe_integer(event.agent_id),
      directive_type: event.metadata[:directive_type] || event.event_name,
      status: event.status,
      payload: persistence_payload(event),
      correlation_id: event.correlation_id
    }

    _ = Observability.log_directive(attrs, @actor)
    :ok
  end

  defp persist(%{kind: "action"} = event) do
    attrs = %{
      workspace_id: event.workspace_id,
      agent_instance_id: maybe_integer(event.agent_id),
      status: event.status,
      payload: persistence_payload(event),
      correlation_id: event.correlation_id
    }

    _ = Observability.log_trace(attrs, @actor)
    :ok
  end

  defp persist(_event), do: :ok

  defp persist_error(%{status: "exception"} = event) do
    attrs = %{
      workspace_id: event.workspace_id,
      agent_instance_id: maybe_integer(event.agent_id),
      status: "error",
      payload: persistence_payload(event),
      correlation_id: event.correlation_id
    }

    _ = Observability.log_error(attrs, @actor)
    :ok
  end

  defp persist_error(_event), do: :ok

  defp persistence_payload(event) do
    %{
      event_name: event.event_name,
      kind: event.kind,
      status: event.status,
      measured_at: event.measured_at,
      duration_native: event.duration_native,
      metadata: event.metadata,
      measurements: event.measurements
    }
  end

  defp pick_workspace_id(metadata) do
    metadata[:workspace_id] || metadata[:jido_workspace_id] || 1
  end

  defp pick_agent_id(metadata) do
    metadata[:agent_instance_id] || metadata[:agent_id]
  end

  defp maybe_integer(nil), do: nil
  defp maybe_integer(v) when is_integer(v), do: v

  defp maybe_integer(v) when is_binary(v) do
    case Integer.parse(v) do
      {int, ""} -> int
      _ -> nil
    end
  end

  defp maybe_integer(_), do: nil

  defp scrub_metadata(metadata) do
    metadata
    |> Map.take([
      :agent_id,
      :agent_module,
      :signal_type,
      :directive_type,
      :workflow_id,
      :action,
      :error,
      :jido_instance,
      :jido_trace_id,
      :jido_span_id,
      :jido_parent_span_id
    ])
    |> Enum.reject(fn {_k, v} -> is_pid(v) or is_reference(v) or is_function(v) end)
    |> Map.new()
  end

  defp publish_state_change(%{event: [:jido, :agent, :cmd, :stop]} = event) do
    agent_id = event.agent_id

    if agent_id do
      state = Map.get(event.metadata, :state, %{})
      _ = Roster.update_agent_state(event.workspace_id, to_string(agent_id), state)

      publish(
        %{
          agent_id: agent_id,
          workspace_id: event.workspace_id,
          timestamp: DateTime.utc_now(),
          state: state
        },
        EventBus.agent_state_topic(event.workspace_id, agent_id)
      )
    end

    :ok
  end

  defp publish_state_change(_event), do: :ok

end
