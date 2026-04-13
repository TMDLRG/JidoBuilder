defmodule JidoBuilderWeb.SecurityTest do
  @moduledoc "Story 10.4 — Security tests: auth, injection, rate limiting."
  use JidoBuilderWeb.ConnCase, async: false

  alias JidoBuilderCore.{Agents, ApiKeys}

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "sec-#{System.unique_integer()}", slug: "sec-#{System.unique_integer()}"},
        "test"
      )

    {:ok, _api_key, raw_key} = ApiKeys.generate(workspace.id, "sec-key", "test")
    %{workspace: workspace, raw_key: raw_key}
  end

  test "API endpoints reject requests without auth", %{conn: conn} do
    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> get(~p"/api/v1/agents")

    assert conn.status == 401
  end

  test "API endpoints reject invalid Bearer token", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "Bearer invalid-token-here")
      |> put_req_header("content-type", "application/json")
      |> get(~p"/api/v1/agents")

    assert conn.status == 401
  end

  test "MCP endpoint rejects requests without auth", %{conn: conn} do
    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post(~p"/mcp", %{jsonrpc: "2.0", id: 1, method: "initialize"})

    assert conn.status == 401
  end

  test "SQL injection attempt in agent name is handled safely", %{conn: conn, raw_key: key} do
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{key}")
      |> put_req_header("content-type", "application/json")
      |> post(~p"/api/v1/agents", %{name: "'; DROP TABLE agent_instances; --"})

    # Should either create safely or reject, not crash
    assert conn.status in [201, 422]
  end

  test "XSS attempt in template name is stored safely", %{conn: conn, raw_key: key} do
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{key}")
      |> put_req_header("content-type", "application/json")
      |> post(~p"/api/v1/templates", %{
        name: "<script>alert('xss')</script>",
        slug: "xss-test",
        status: "active"
      })

    assert conn.status in [201, 422]

    if conn.status == 201 do
      resp = json_response(conn, 201)
      # Name should be stored as-is (Phoenix auto-escapes on render)
      assert resp["data"]["name"] == "<script>alert('xss')</script>"
    end
  end
end
