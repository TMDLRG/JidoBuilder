defmodule JidoBuilderCore.Observability.DirectiveLog do
  use JidoBuilderCore.Schema

  schema "directive_logs" do
    field(:directive_type, :string)
    field(:status, :string)
    field(:payload, :map, default: %{})
    field(:correlation_id, :string)

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)
    belongs_to(:agent_instance, JidoBuilderCore.Agents.AgentInstance)

    timestamps(updated_at: false)
  end

  def changeset(directive_log, attrs) do
    directive_log
    |> cast(attrs, [
      :workspace_id,
      :agent_instance_id,
      :directive_type,
      :status,
      :payload,
      :correlation_id
    ])
    |> validate_required([:workspace_id, :directive_type, :status])
  end
end
