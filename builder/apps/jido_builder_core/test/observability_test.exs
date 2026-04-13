defmodule JidoBuilderCore.ObservabilityTest do
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, Observability, Repo}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "ObsTest", slug: "obs-#{System.unique_integer([:positive])}"},
        "tester"
      )

    %{workspace: workspace}
  end

  describe "get_by_correlation_id/2" do
    test "returns signal_logs matching the correlation_id", %{workspace: workspace} do
      correlation_id = Ecto.UUID.generate()

      {:ok, _log} =
        Observability.log_signal(
          %{
            workspace_id: workspace.id,
            direction: "inbound",
            signal_type: "test.signal",
            payload: %{foo: "bar"},
            correlation_id: correlation_id
          },
          "tester"
        )

      # Log a second signal with different correlation_id (noise)
      {:ok, _} =
        Observability.log_signal(
          %{
            workspace_id: workspace.id,
            direction: "inbound",
            signal_type: "test.other",
            payload: %{},
            correlation_id: Ecto.UUID.generate()
          },
          "tester"
        )

      result = Observability.get_by_correlation_id(workspace.id, correlation_id)

      assert %{signal_logs: signal_logs, directive_logs: directive_logs} = result
      assert length(signal_logs) == 1
      assert hd(signal_logs).correlation_id == correlation_id
      assert hd(signal_logs).signal_type == "test.signal"
      assert directive_logs == []
    end

    test "returns directive_logs matching the correlation_id", %{workspace: workspace} do
      correlation_id = Ecto.UUID.generate()

      {:ok, _log} =
        Observability.log_directive(
          %{
            workspace_id: workspace.id,
            directive_type: "test.directive",
            status: "ok",
            payload: %{result: "success"},
            correlation_id: correlation_id
          },
          "tester"
        )

      result = Observability.get_by_correlation_id(workspace.id, correlation_id)

      assert %{signal_logs: [], directive_logs: directive_logs} = result
      assert length(directive_logs) == 1
      assert hd(directive_logs).correlation_id == correlation_id
      assert hd(directive_logs).directive_type == "test.directive"
    end

    test "returns both signal and directive logs for same correlation_id", %{
      workspace: workspace
    } do
      correlation_id = Ecto.UUID.generate()

      {:ok, _} =
        Observability.log_signal(
          %{
            workspace_id: workspace.id,
            direction: "inbound",
            signal_type: "dispatch.call",
            payload: %{},
            correlation_id: correlation_id
          },
          "tester"
        )

      {:ok, _} =
        Observability.log_directive(
          %{
            workspace_id: workspace.id,
            directive_type: "action.completed",
            status: "ok",
            payload: %{elapsed_ms: 42},
            correlation_id: correlation_id
          },
          "tester"
        )

      {:ok, _} =
        Observability.log_error(
          %{
            workspace_id: workspace.id,
            payload: %{error: "timeout"},
            correlation_id: correlation_id
          },
          "tester"
        )

      result = Observability.get_by_correlation_id(workspace.id, correlation_id)

      assert length(result.signal_logs) == 1
      # log_directive + log_error = 2 directive_logs
      assert length(result.directive_logs) == 2
    end

    test "returns empty lists when correlation_id does not exist", %{workspace: workspace} do
      result = Observability.get_by_correlation_id(workspace.id, Ecto.UUID.generate())

      assert result == %{signal_logs: [], directive_logs: []}
    end
  end
end
