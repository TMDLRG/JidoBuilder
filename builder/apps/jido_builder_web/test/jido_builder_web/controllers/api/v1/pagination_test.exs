defmodule JidoBuilderWeb.Api.V1.PaginationTest do
  @moduledoc "Story 6.3 — Pagination on API endpoints."
  use JidoBuilderWeb.ConnCase, async: false

  alias JidoBuilderCore.{Agents, ApiKeys}
  alias JidoBuilderRuntime.Roster

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "pag-ws-#{System.unique_integer()}", slug: "pag-ws-#{System.unique_integer()}"},
        "test"
      )

    {:ok, _api_key, raw_key} = ApiKeys.generate(workspace.id, "test-key", "test")

    # Create 5 agents
    for i <- 1..5 do
      Roster.hire(workspace.id, "pag-agent-#{i}-#{System.unique_integer([:positive])}", "test")
    end

    %{workspace: workspace, raw_key: raw_key}
  end

  defp api_conn(conn, raw_key) do
    conn
    |> put_req_header("authorization", "Bearer #{raw_key}")
    |> put_req_header("content-type", "application/json")
  end

  test "GET /api/v1/agents?limit=2 returns max 2 results", %{conn: conn, raw_key: key} do
    resp =
      conn
      |> api_conn(key)
      |> get(~p"/api/v1/agents?limit=2")
      |> json_response(200)

    assert length(resp["data"]) == 2
    assert resp["meta"]["limit"] == 2
    assert resp["meta"]["offset"] == 0
    assert resp["meta"]["total"] >= 5
  end

  test "GET /api/v1/agents?offset=3 skips first 3 results", %{conn: conn, raw_key: key} do
    all_resp =
      conn
      |> api_conn(key)
      |> get(~p"/api/v1/agents")
      |> json_response(200)

    total = length(all_resp["data"])

    offset_resp =
      conn
      |> api_conn(key)
      |> get(~p"/api/v1/agents?offset=3")
      |> json_response(200)

    assert length(offset_resp["data"]) == total - 3
    assert offset_resp["meta"]["offset"] == 3
  end

  test "GET /api/v1/agents with no params returns all with default pagination meta", %{conn: conn, raw_key: key} do
    resp =
      conn
      |> api_conn(key)
      |> get(~p"/api/v1/agents")
      |> json_response(200)

    assert is_list(resp["data"])
    assert resp["meta"]["limit"] == 50
    assert resp["meta"]["offset"] == 0
  end

  test "limit is capped at 100", %{conn: conn, raw_key: key} do
    resp =
      conn
      |> api_conn(key)
      |> get(~p"/api/v1/agents?limit=999")
      |> json_response(200)

    assert resp["meta"]["limit"] == 100
  end
end
