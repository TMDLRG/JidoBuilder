defmodule JidoBuilderCore.Observability.SignalLog do
  use JidoBuilderCore.Schema

  schema "signal_logs" do
    field(:direction, :string)
    field(:signal_type, :string)
    field(:payload, :map, default: %{})
    field(:correlation_id, :string)

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)
    belongs_to(:agent_instance, JidoBuilderCore.Agents.AgentInstance)
    belongs_to(:template, JidoBuilderCore.Templates.Template)

    timestamps(updated_at: false)
  end

  def changeset(signal_log, attrs) do
    signal_log
    |> cast(attrs, [
      :workspace_id,
      :agent_instance_id,
      :template_id,
      :direction,
      :signal_type,
      :payload,
      :correlation_id
    ])
    |> validate_required([:workspace_id, :direction, :signal_type])
  end
end
