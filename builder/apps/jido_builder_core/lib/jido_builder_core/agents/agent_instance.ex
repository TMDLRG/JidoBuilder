defmodule JidoBuilderCore.Agents.AgentInstance do
  use JidoBuilderCore.Schema

  schema "agent_instances" do
    field(:name, :string)
    field(:status, :string)
    field(:runtime_pid, :string)
    field(:state, :map, default: %{})
    field(:metadata, :map, default: %{})
    field(:last_seen_at, :utc_datetime_usec)

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)
    belongs_to(:partition, JidoBuilderCore.Agents.Partition)
    belongs_to(:template, JidoBuilderCore.Templates.Template)

    timestamps()
  end

  def changeset(agent_instance, attrs) do
    agent_instance
    |> cast(attrs, [
      :workspace_id,
      :partition_id,
      :template_id,
      :name,
      :status,
      :runtime_pid,
      :state,
      :metadata,
      :last_seen_at
    ])
    |> validate_required([:workspace_id, :name, :status])
  end
end
