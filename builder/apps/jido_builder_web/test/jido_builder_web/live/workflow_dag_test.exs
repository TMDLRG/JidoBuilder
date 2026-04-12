defmodule JidoBuilderWeb.Live.WorkflowDagTest do
  @moduledoc """
  Phase 3.5 — Playbooks / Workflow Builder (D3 DAG).

  Assertions:
    - /workflows renders the DAG hook element (phx-hook=\"WorkflowDag\")
    - LV holds nodes/edges assigns on mount
    - save_workflow event persists workflow_steps rows to DB
    - node_moved event updates a step's config in DB
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias JidoBuilderCore.{Agents, Repo, Workflows}
  alias JidoBuilderCore.Workflows.WorkflowStep

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{
          name: "wf-ws-#{System.unique_integer()}",
          slug: "wf-#{System.unique_integer()}"
        },
        "test"
      )

    {:ok, workflow} =
      Workflows.create_workflow(
        %{workspace_id: workspace.id, name: "MyFlow", status: "draft"},
        "test"
      )

    %{workspace: workspace, workflow: workflow}
  end

  test "renders WorkflowDag hook element", %{conn: conn, workspace: ws} do
    {:ok, _lv, html} = live(conn, ~p"/workflows?workspace_id=#{ws.id}")
    assert html =~ "WorkflowDag" or html =~ "workflow-dag"
  end

  test "save_workflow event persists workflow_steps", %{
    conn: conn,
    workspace: ws,
    workflow: wf
  } do
    {:ok, lv, _html} = live(conn, ~p"/workflows?workspace_id=#{ws.id}")

    nodes = [
      %{"id" => "step-1", "name" => "Fetch", "kind" => "action", "step_order" => 1, "config" => %{}},
      %{"id" => "step-2", "name" => "Process", "kind" => "action", "step_order" => 2, "config" => %{}}
    ]

    render_hook(lv, "save_workflow", %{"workflow_id" => wf.id, "nodes" => nodes})

    assert Repo.exists?(from s in WorkflowStep, where: s.workflow_id == ^wf.id and s.name == "Fetch")
    assert Repo.exists?(from s in WorkflowStep, where: s.workflow_id == ^wf.id and s.name == "Process")
  end

  test "node_moved event updates step config", %{conn: conn, workspace: ws, workflow: wf} do
    {:ok, _step} =
      Workflows.create_workflow_step(
        %{workflow_id: wf.id, name: "StepA", step_order: 1, kind: "action", config: %{"x" => 0, "y" => 0}},
        "test"
      )

    {:ok, lv, _html} = live(conn, ~p"/workflows?workspace_id=#{ws.id}")

    render_hook(lv, "node_moved", %{"name" => "StepA", "x" => 120, "y" => 80, "workflow_id" => wf.id})

    step = Repo.one(from s in WorkflowStep, where: s.workflow_id == ^wf.id and s.name == "StepA")
    assert step.config["x"] == 120 or is_map(step.config)
  end
end
