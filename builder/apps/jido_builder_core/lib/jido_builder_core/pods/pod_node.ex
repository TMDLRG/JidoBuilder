defmodule JidoBuilderCore.Pods.PodNode do
  use JidoBuilderCore.Schema

  schema "pod_nodes" do
    field(:name, :string)
    field(:role, :string)
    field(:position, :integer)
    field(:metadata, :map, default: %{})

    belongs_to(:pod_topology, JidoBuilderCore.Pods.PodTopology)
    belongs_to(:agent_instance, JidoBuilderCore.Agents.AgentInstance)

    timestamps()
  end

  def changeset(pod_node, attrs) do
    pod_node
    |> cast(attrs, [:pod_topology_id, :agent_instance_id, :name, :role, :position, :metadata])
    |> validate_required([:pod_topology_id, :name, :role, :position])
  end
end
