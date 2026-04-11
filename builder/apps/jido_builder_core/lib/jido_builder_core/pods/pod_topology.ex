defmodule JidoBuilderCore.Pods.PodTopology do
  use JidoBuilderCore.Schema

  schema "pod_topologies" do
    field(:name, :string)
    field(:strategy, :string)
    field(:metadata, :map, default: %{})

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)
    has_many(:nodes, JidoBuilderCore.Pods.PodNode)

    timestamps()
  end

  def changeset(pod_topology, attrs) do
    pod_topology
    |> cast(attrs, [:workspace_id, :name, :strategy, :metadata])
    |> validate_required([:workspace_id, :name, :strategy])
  end
end
