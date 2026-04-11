defmodule JidoBuilderCore.Workflows.WorkflowStep do
  use JidoBuilderCore.Schema

  schema "workflow_steps" do
    field(:name, :string)
    field(:step_order, :integer)
    field(:kind, :string)
    field(:config, :map, default: %{})

    belongs_to(:workflow, JidoBuilderCore.Workflows.Workflow)

    timestamps()
  end

  def changeset(workflow_step, attrs) do
    workflow_step
    |> cast(attrs, [:workflow_id, :name, :step_order, :kind, :config])
    |> validate_required([:workflow_id, :name, :step_order, :kind])
  end
end
