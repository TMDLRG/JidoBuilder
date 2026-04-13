defmodule JidoBuilderCore.Notebooks.Notebook do
  @moduledoc """
  Ecto schema for Notebooks.

  A Notebook contains cells (code, markdown, output) for interactive
  agent development. Cells are stored as a JSON array.
  """

  use JidoBuilderCore.Schema

  schema "notebooks" do
    field(:name, :string)
    field(:description, :string)
    field(:cells, {:array, :map}, default: [])
    field(:metadata, :map, default: %{})

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)

    timestamps()
  end

  def changeset(notebook, attrs) do
    notebook
    |> cast(attrs, [:workspace_id, :name, :description, :cells, :metadata])
    |> validate_required([:workspace_id, :name])
  end
end
