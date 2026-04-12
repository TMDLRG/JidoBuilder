defmodule JidoBuilderCore.Workflows.WorkflowEdge do
  use JidoBuilderCore.Schema

  schema "workflow_edges" do
    field :label, :string
    field :condition, :map, default: %{}

    belongs_to :workflow, JidoBuilderCore.Workflows.Workflow
    belongs_to :source_step, JidoBuilderCore.Workflows.WorkflowStep
    belongs_to :target_step, JidoBuilderCore.Workflows.WorkflowStep

    timestamps()
  end

  def changeset(edge, attrs) do
    edge
    |> cast(attrs, [:workflow_id, :source_step_id, :target_step_id, :label, :condition])
    |> validate_required([:workflow_id, :source_step_id, :target_step_id])
  end
end
