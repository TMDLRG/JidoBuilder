defmodule JidoBuilderCore.Audit.AuditEvent do
  use JidoBuilderCore.Schema

  schema "audit_events" do
    field(:actor, :string)
    field(:action, :string)
    field(:entity_type, :string)
    field(:entity_id, :string)
    field(:metadata, :map, default: %{})
    field(:occurred_at, :utc_datetime_usec)

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)

    timestamps(updated_at: false)
  end

  def changeset(audit_event, attrs) do
    audit_event
    |> cast(attrs, [
      :workspace_id,
      :actor,
      :action,
      :entity_type,
      :entity_id,
      :metadata,
      :occurred_at
    ])
    |> validate_required([:action, :entity_type, :entity_id, :occurred_at])
  end
end
