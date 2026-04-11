defmodule JidoBuilderCore.Agents.Workspace do
  use JidoBuilderCore.Schema

  schema "workspaces" do
    field(:name, :string)
    field(:slug, :string)
    field(:metadata, :map, default: %{})

    has_many(:partitions, JidoBuilderCore.Agents.Partition)

    timestamps()
  end

  def changeset(workspace, attrs) do
    workspace
    |> cast(attrs, [:name, :slug, :metadata])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
  end
end
