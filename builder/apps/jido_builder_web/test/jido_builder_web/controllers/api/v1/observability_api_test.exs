defmodule JidoBuilderWeb.Api.V1.ObservabilityApiTest do
  @moduledoc "Story 4.3 — Observability API tests."
  use JidoBuilderWeb.ConnCase, async: false

  alias JidoBuilderCore.{Agents, ApiKeys, Observability}

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "obs-api-#{System.unique_integer()}", slug: "obs-api-#{System.unique_integer()}"},
        "test"
      )

    {:ok, _api_key, raw_key} = ApiKeys.generate(workspace.id, "test-key", "test")

    # Log a signal
    Observability.log_signal(
      %{workspace_id: workspace.id, signal_type: "test-signal", direction: "inbound", payload: %{}, correlation_id: "test-corr-123"},
      "test"
    )

    %{workspace: workspace, raw_key: raw_key}
  end

  defp api(conn, key), do: conn |> put_req_header("authorization", "Bearer #{key}")

  test "GET /api/v1/signals returns signal history", %{conn: conn, raw_key: key} do
    conn = conn |> api(key) |> get(~p"/api/v1/signals")
    assert %{"data" => signals} = json_response(conn, 200)
    assert is_list(signals)
    assert Enum.any?(signals, fn s -> s["signal_type"] == "test-signal" end)
  end

  test "GET /api/v1/errors returns empty when no errors", %{conn: conn, raw_key: key} do
    conn = conn |> api(key) |> get(~p"/api/v1/errors")
    assert %{"data" => []} = json_response(conn, 200)
  end

  test "GET /api/v1/correlation/:id returns matching logs", %{conn: conn, raw_key: key} do
    conn = conn |> api(key) |> get(~p"/api/v1/correlation/test-corr-123")
    assert %{"data" => %{"signal_logs" => sigs}} = json_response(conn, 200)
    assert length(sigs) >= 1
  end
end
