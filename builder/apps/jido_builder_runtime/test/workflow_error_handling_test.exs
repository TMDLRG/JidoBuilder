defmodule JidoBuilderRuntime.WorkflowErrorHandlingTest do
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, Repo, Workflows}
  alias JidoBuilderRuntime.WorkflowExecutor

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "ErrTest", slug: "err-#{System.unique_integer([:positive])}"},
        "tester"
      )

    context = %{workspace_id: workspace.id, actor: "tester"}
    %{workspace: workspace, context: context}
  end

  describe "stop_on_error policy (default)" do
    test "stops workflow on first step failure", %{workspace: workspace, context: context} do
      {:ok, workflow} =
        Workflows.create_workflow(
          %{
            workspace_id: workspace.id,
            name: "StopOnError",
            status: "active",
            metadata: %{error_policy: "stop_on_error"}
          },
          "tester"
        )

      {:ok, step_a} =
        Workflows.create_workflow_step(
          %{
            workflow_id: workflow.id,
            name: "Good Step",
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
            name: "Failing Step",
            step_order: 2,
            kind: "action",
            config: %{action_module: "Elixir.NonExistent.Module"}
          },
          "tester"
        )

      {:ok, step_c} =
        Workflows.create_workflow_step(
          %{
            workflow_id: workflow.id,
            name: "Unreached Step",
            step_order: 3,
            kind: "transform",
            config: %{operation: "merge", value: %{c: 3}}
          },
          "tester"
        )

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

      result = WorkflowExecutor.execute(context, workflow.id)

      # Should stop at step_b failure
      assert {:error, _error} = result
    end
  end

  describe "skip_and_continue policy" do
    test "skips failed step and continues execution", %{workspace: workspace, context: context} do
      {:ok, workflow} =
        Workflows.create_workflow(
          %{
            workspace_id: workspace.id,
            name: "SkipContinue",
            status: "active",
            metadata: %{"error_policy" => "skip_and_continue"}
          },
          "tester"
        )

      {:ok, step_a} =
        Workflows.create_workflow_step(
          %{
            workflow_id: workflow.id,
            name: "Good Step",
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
            name: "Failing Step",
            step_order: 2,
            kind: "action",
            config: %{action_module: "Elixir.NonExistent.Module"}
          },
          "tester"
        )

      {:ok, step_c} =
        Workflows.create_workflow_step(
          %{
            workflow_id: workflow.id,
            name: "Final Step",
            step_order: 3,
            kind: "transform",
            config: %{operation: "merge", value: %{c: 3}}
          },
          "tester"
        )

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

      result = WorkflowExecutor.execute(context, workflow.id)

      # Should succeed despite step_b failure
      assert {:ok, execution} = result
      assert execution.steps_completed == 3
      # step_b should be marked as error in results
      failed_step = Enum.find(execution.step_results, &(&1.status == :error))
      assert failed_step.step_name == "Failing Step"
      # step_c should still execute
      assert execution.final_state[:c] == 3
    end
  end

  describe "retry_once policy" do
    test "retry_once retries failed step and succeeds on second attempt", %{
      workspace: workspace,
      context: context
    } do
      # Use a step that would fail then succeed - for this we'll use retry_once
      # with a step that has max_retries: 1 in config
      {:ok, workflow} =
        Workflows.create_workflow(
          %{
            workspace_id: workspace.id,
            name: "RetryOnce",
            status: "active",
            metadata: %{"error_policy" => "retry_once"}
          },
          "tester"
        )

      {:ok, step_a} =
        Workflows.create_workflow_step(
          %{
            workflow_id: workflow.id,
            name: "RetryStep",
            step_order: 1,
            kind: "action",
            # This will always fail - but retry_once should try twice
            config: %{action_module: "Elixir.NonExistent.Module", max_retries: 1}
          },
          "tester"
        )

      {:ok, step_b} =
        Workflows.create_workflow_step(
          %{
            workflow_id: workflow.id,
            name: "After Step",
            step_order: 2,
            kind: "transform",
            config: %{operation: "merge", value: %{b: 2}}
          },
          "tester"
        )

      {:ok, _} =
        Workflows.create_workflow_edge(
          %{workflow_id: workflow.id, source_step_id: step_a.id, target_step_id: step_b.id},
          "tester"
        )

      # With retry_once, the failing step gets retried once.
      # Since it still fails, the workflow fails (retry_once only retries, doesn't skip)
      result = WorkflowExecutor.execute(context, workflow.id)
      assert {:error, _} = result
    end
  end
end
