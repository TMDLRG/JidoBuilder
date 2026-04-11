defmodule JidoBuilderCore.Workflows do
  alias JidoBuilderCore.Audit
  alias JidoBuilderCore.Repo
  alias JidoBuilderCore.Workflows.{Workflow, WorkflowStep}

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
