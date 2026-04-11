defmodule JidoBuilderCore.Workflows.Workflow do
  use JidoBuilderCore.Schema

  schema "workflows" do
    field(:name, :string)
    field(:description, :string)
    field(:status, :string)
    field(:metadata, :map, default: %{})

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)
    has_many(:steps, JidoBuilderCore.Workflows.WorkflowStep)

    timestamps()
  end

  def changeset(workflow, attrs) do
    workflow
    |> cast(attrs, [:workspace_id, :name, :description, :status, :metadata])
    |> validate_required([:workspace_id, :name, :status])
  end
end
