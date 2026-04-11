defmodule JidoBuilderRuntime.EventBus do
  @moduledoc """
  PubSub topic helpers for runtime telemetry fan-out.
  """

  @spec workspace_activity_topic(pos_integer()) :: String.t()
  def workspace_activity_topic(workspace_id),
    do: "workspace:" <> to_string(workspace_id) <> ":activity"

  @spec agent_topic(pos_integer(), String.t() | pos_integer()) :: String.t()
  def agent_topic(workspace_id, agent_id),
    do: "workspace:" <> to_string(workspace_id) <> ":agent:" <> to_string(agent_id) <> ":events"

  @spec workflow_topic(pos_integer(), String.t() | pos_integer()) :: String.t()
  def workflow_topic(workspace_id, workflow_id),
    do:
      "workspace:" <>
        to_string(workspace_id) <> ":workflow:" <> to_string(workflow_id) <> ":events"

  @spec workflow_activity_topic(pos_integer()) :: String.t()
  def workflow_activity_topic(workspace_id),
    do: "workspace:" <> to_string(workspace_id) <> ":workflow:activity"
end
