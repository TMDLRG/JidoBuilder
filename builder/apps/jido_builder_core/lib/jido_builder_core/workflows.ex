defmodule JidoBuilderCore.Workflows do
  import Ecto.Query

  alias JidoBuilderCore.Audit
  alias JidoBuilderCore.Repo
  alias JidoBuilderCore.Workflows.{Workflow, WorkflowStep, WorkflowEdge}

  def list_workflows(workspace_id) do
    Workflow
    |> where([w], w.workspace_id == ^workspace_id)
    |> Repo.all()
  end

  def list_workflow_steps(workflow_id) do
    WorkflowStep
    |> where([s], s.workflow_id == ^workflow_id)
    |> order_by([s], s.step_order)
    |> Repo.all()
  end

  def get_workflow(id), do: Repo.get(Workflow, id)

  def update_workflow_step(step, attrs, actor) do
    step
    |> WorkflowStep.changeset(attrs)
    |> Repo.update()
    |> maybe_audit(actor, "workflows.steps.update")
  end

  def delete_workflow_steps(workflow_id) do
    WorkflowStep
    |> where([s], s.workflow_id == ^workflow_id)
    |> Repo.delete_all()
  end

  def create_workflow(attrs, actor),
    do: insert_with_audit(Workflow, attrs, actor, "workflows.create")

  def create_workflow_step(attrs, actor),
    do: insert_with_audit(WorkflowStep, attrs, actor, "workflows.steps.create")

  def update_workflow(workflow, attrs, actor) do
    workflow
    |> Workflow.changeset(attrs)
    |> Repo.update()
    |> maybe_audit(actor, "workflows.update")
  end

  defp insert_with_audit(schema, attrs, actor, action) do
    struct(schema)
    |> schema.changeset(attrs)
    |> Repo.insert()
    |> maybe_audit(actor, action)
  end

  defp maybe_audit({:ok, record} = ok, actor, action) do
    _ = Audit.log(actor, action, record, %{})
    ok
  end

  defp maybe_audit(error, _actor, _action), do: error
end


  def list_workflow_edges(workflow_id) do
    WorkflowEdge
    |> where([e], e.workflow_id == ^workflow_id)
    |> Repo.all()
  end

  def create_workflow_edge(attrs, actor),
    do: insert_with_audit(WorkflowEdge, attrs, actor, "workflows.edges.create")

  def delete_workflow_edge(edge, actor) do
    edge
    |> Repo.delete()
    |> maybe_audit(actor, "workflows.edges.delete")
  end
