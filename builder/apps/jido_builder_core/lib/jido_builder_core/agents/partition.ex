defmodule JidoBuilderCore.Agents.Partition do
  use JidoBuilderCore.Schema

  schema "partitions" do
    field(:name, :string)
    field(:key, :string)
    field(:metadata, :map, default: %{})

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)

    timestamps()
  end

  def changeset(partition, attrs) do
    partition
    |> cast(attrs, [:workspace_id, :name, :key, :metadata])
    |> validate_required([:workspace_id, :name, :key])
    |> unique_constraint(:key, name: :partitions_workspace_id_key_index)
  end
end
