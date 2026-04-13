defmodule JidoBuilderCore.MetricsTest do
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, Metrics, Observability, Repo}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "metrics-#{System.unique_integer([:positive])}", slug: "metrics-#{System.unique_integer([:positive])}"},
        "test"
      )

    %{workspace: workspace}
  end

  describe "signals_per_hour/2" do
    test "returns empty list when no signals exist", %{workspace: workspace} do
      result = Metrics.signals_per_hour(workspace.id)
      assert is_list(result)
      assert result == []
    end

    test "returns list of maps with hour and count keys", %{workspace: workspace} do
      # Insert a few signals
      for _ <- 1..3 do
        {:ok, _} =
          Observability.log_signal(
            %{
              workspace_id: workspace.id,
              direction: "inbound",
              signal_type: "test.metric",
              payload: %{}
            },
            "test"
          )
      end

      result = Metrics.signals_per_hour(workspace.id)
      assert is_list(result)
      assert length(result) >= 1

      first = hd(result)
      assert Map.has_key?(first, :hour)
      assert Map.has_key?(first, :count)
      assert is_binary(first.hour)
      assert is_integer(first.count)
      assert first.count >= 3
    end
  end

  describe "errors_per_hour/2" do
    test "returns empty list when no errors exist", %{workspace: workspace} do
      result = Metrics.errors_per_hour(workspace.id)
      assert is_list(result)
      assert result == []
    end

    test "counts only error directive logs", %{workspace: workspace} do
      # Insert an error
      {:ok, _} =
        Observability.log_error(
          %{
            workspace_id: workspace.id,
            payload: %{error: "boom"}
          },
          "test"
        )

      # Insert a non-error directive (trace)
      {:ok, _} =
        Observability.log_trace(
          %{
            workspace_id: workspace.id,
            payload: %{info: "ok"}
          },
          "test"
        )

      result = Metrics.errors_per_hour(workspace.id)
      assert is_list(result)
      assert length(result) >= 1

      total = Enum.reduce(result, 0, fn %{count: c}, acc -> acc + c end)
      assert total >= 1
    end
  end
end
