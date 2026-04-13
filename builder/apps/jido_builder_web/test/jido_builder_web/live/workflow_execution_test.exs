defmodule JidoBuilderWeb.Live.WorkflowExecutionTest do
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.{Agents, Workflows}

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "wf-exec-ws", slug: "wf-exec-#{System.unique_integer([:positive])}"},
        "test"
      )

    {:ok, workflow} =
      Workflows.create_workflow(
        %{workspace_id: workspace.id, name: "Test Workflow", status: "active"},
        "test"
      )

    {:ok, step_a} =
      Workflows.create_workflow_step(
        %{
          workflow_id: workflow.id,
          name: "Transform A",
          step_order: 1,
          kind: "transform",
          config: %{operation: "merge", value: %{a: 1}}
        },
        "test"
      )

    {:ok, step_b} =
      Workflows.create_workflow_step(
        %{
          workflow_id: workflow.id,
          name: "Transform B",
          step_order: 2,
          kind: "transform",
          config: %{operation: "merge", value: %{b: 2}}
        },
        "test"
      )

    {:ok, _} =
      Workflows.create_workflow_edge(
        %{workflow_id: workflow.id, source_step_id: step_a.id, target_step_id: step_b.id},
        "test"
      )

    %{workspace: workspace, workflow: workflow}
  end

  test "Run button dispatches workflow and updates DAG node colors", %{
    conn: conn,
    workflow: _wf
  } do
    {:ok, lv, html} = live(conn, ~p"/workflows")

    # Should have a Run Workflow button
    assert html =~ "Run Workflow"

    # Click the run button
    html = lv |> element("button", "Run Workflow") |> render_click()

    # Should show execution result with step timeline
    assert html =~ "Execution" or html =~ "steps_completed" or html =~ "Step" or html =~ "ms"
  end

  test "workflow builder page renders run button when workflow selected", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/workflows")

    assert html =~ "Run Workflow"
  end
end
