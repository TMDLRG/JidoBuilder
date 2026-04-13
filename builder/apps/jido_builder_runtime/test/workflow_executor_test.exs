defmodule JidoBuilderRuntime.WorkflowExecutorTest do
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, Repo, Workflows}
  alias JidoBuilderRuntime.WorkflowExecutor

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "WFExec", slug: "wfexec-#{System.unique_integer([:positive])}"},
        "tester"
      )

    context = %{workspace_id: workspace.id, actor: "tester"}

    %{workspace: workspace, context: context}
  end

  describe "execute/2" do
    test "executes 3-step linear workflow returning accumulated state", %{
      workspace: workspace,
      context: context
    } do
      # Create workflow with 3 steps connected linearly: A -> B -> C
      {:ok, workflow} =
        Workflows.create_workflow(
          %{workspace_id: workspace.id, name: "Linear 3-Step", status: "active"},
          "tester"
        )

      {:ok, step_a} =
        Workflows.create_workflow_step(
          %{
            workflow_id: workflow.id,
            name: "Step A",
            step_order: 1,
            kind: "transform",
            config: %{operation: "merge", value: %{a: 1}}
          },
          "tester"
        )

      {:ok, step_b} =
        Workflows.create_workflow_step(
          %{
            workflow_id: workflow.id,
            name: "Step B",
            step_order: 2,
            kind: "transform",
            config: %{operation: "merge", value: %{b: 2}}
          },
          "tester"
        )

      {:ok, step_c} =
        Workflows.create_workflow_step(
          %{
            workflow_id: workflow.id,
            name: "Step C",
            step_order: 3,
            kind: "transform",
            config: %{operation: "merge", value: %{c: 3}}
          },
          "tester"
        )

      # Create edges: A -> B -> C
      {:ok, _} =
        Workflows.create_workflow_edge(
          %{workflow_id: workflow.id, source_step_id: step_a.id, target_step_id: step_b.id},
          "tester"
        )

      {:ok, _} =
        Workflows.create_workflow_edge(
          %{workflow_id: workflow.id, source_step_id: step_b.id, target_step_id: step_c.id},
          "tester"
        )

      # Execute the workflow
      result = WorkflowExecutor.execute(context, workflow.id)

      assert {:ok, execution} = result
      assert execution.steps_completed == 3
      assert is_integer(execution.elapsed_ms)
      assert execution.elapsed_ms >= 0
      assert is_list(execution.step_results)
      assert length(execution.step_results) == 3
      # Final state should have accumulated all merges
      assert execution.final_state[:a] == 1
      assert execution.final_state[:b] == 2
      assert execution.final_state[:c] == 3
    end

    test "returns error for non-existent workflow", %{context: context} do
      result = WorkflowExecutor.execute(context, -1)
      assert {:error, _} = result
    end

    test "handles empty workflow with no steps", %{workspace: workspace, context: context} do
      {:ok, workflow} =
        Workflows.create_workflow(
          %{workspace_id: workspace.id, name: "Empty", status: "active"},
          "tester"
        )

      result = WorkflowExecutor.execute(context, workflow.id)
      assert {:ok, execution} = result
      assert execution.steps_completed == 0
      assert execution.step_results == []
    end

    test "single step workflow executes correctly", %{workspace: workspace, context: context} do
      {:ok, workflow} =
        Workflows.create_workflow(
          %{workspace_id: workspace.id, name: "Single", status: "active"},
          "tester"
        )

      {:ok, _step} =
        Workflows.create_workflow_step(
          %{
            workflow_id: workflow.id,
            name: "Only Step",
            step_order: 1,
            kind: "transform",
            config: %{operation: "merge", value: %{x: 42}}
          },
          "tester"
        )

      result = WorkflowExecutor.execute(context, workflow.id)
      assert {:ok, execution} = result
      assert execution.steps_completed == 1
      assert execution.final_state[:x] == 42
    end

    test "all step results include shared correlation_id", %{
      workspace: workspace,
      context: context
    } do
      {:ok, workflow} =
        Workflows.create_workflow(
          %{workspace_id: workspace.id, name: "Correlated", status: "active"},
          "tester"
        )

      {:ok, step_a} =
        Workflows.create_workflow_step(
          %{
            workflow_id: workflow.id,
            name: "S1",
            step_order: 1,
            kind: "transform",
            config: %{operation: "merge", value: %{done: true}}
          },
          "tester"
        )

      {:ok, step_b} =
        Workflows.create_workflow_step(
          %{
            workflow_id: workflow.id,
            name: "S2",
            step_order: 2,
            kind: "transform",
            config: %{operation: "merge", value: %{also_done: true}}
          },
          "tester"
        )

      {:ok, _} =
        Workflows.create_workflow_edge(
          %{workflow_id: workflow.id, source_step_id: step_a.id, target_step_id: step_b.id},
          "tester"
        )

      {:ok, execution} = WorkflowExecutor.execute(context, workflow.id)

      assert is_binary(execution.correlation_id)

      Enum.each(execution.step_results, fn step_result ->
        assert step_result.correlation_id == execution.correlation_id
      end)
    end
  end
end
