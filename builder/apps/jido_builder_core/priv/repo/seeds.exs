alias JidoBuilderCore.Repo
alias JidoBuilderCore.Agents.Workspace
alias JidoBuilderCore.Workflows.{Workflow, WorkflowStep}

workspace_slug = "demo-workspace"

workspace =
  Repo.get_by(Workspace, slug: workspace_slug) ||
    Repo.insert!(%Workspace{
      name: "Demo Workspace",
      slug: workspace_slug,
      metadata: %{seeded: true}
    })

workflow_name = "First Workflow"

workflow =
  Repo.get_by(Workflow, workspace_id: workspace.id, name: workflow_name) ||
    Repo.insert!(%Workflow{
      workspace_id: workspace.id,
      name: workflow_name,
      description: "Seeded workflow used by docs smoke tests.",
      status: "draft",
      metadata: %{seeded: true, smoke_test: true}
    })

steps = [
  %{
    name: "Collect Input",
    step_order: 1,
    kind: "signal",
    config: %{signal: "input.received"}
  },
  %{
    name: "Run Runtime",
    step_order: 2,
    kind: "runtime",
    config: %{agent: "demo-1", action: "execute"}
  },
  %{
    name: "Publish Output",
    step_order: 3,
    kind: "emit",
    config: %{signal: "output.published"}
  }
]

Enum.each(steps, fn step_attrs ->
  existing =
    Repo.get_by(WorkflowStep,
      workflow_id: workflow.id,
      name: step_attrs.name,
      step_order: step_attrs.step_order
    )

  if is_nil(existing) do
    Repo.insert!(struct(WorkflowStep, Map.put(step_attrs, :workflow_id, workflow.id)))
  end
end)

IO.puts("Seeded workspace=#{workspace.slug} workflow=\"#{workflow.name}\" with #{length(steps)} steps")
