defmodule JidoBuilderCore.Agents.Snapshot do
  use JidoBuilderCore.Schema

  schema "snapshots" do
    field(:hibernate_metadata, :map, default: %{})
    field(:thaw_metadata, :map, default: %{})
    field(:captured_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)
    belongs_to(:agent_instance, JidoBuilderCore.Agents.AgentInstance)

    timestamps()
  end

  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, [
      :workspace_id,
      :agent_instance_id,
      :hibernate_metadata,
      :thaw_metadata,
      :captured_at,
      :metadata
    ])
    |> validate_required([:workspace_id, :agent_instance_id, :captured_at])
  end
end
