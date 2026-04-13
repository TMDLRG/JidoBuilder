defmodule JidoBuilderWeb.MCP.McpSseTest do
  @moduledoc "Story 5.4 — MCP SSE transport tests."
  use JidoBuilderWeb.ConnCase, async: false

  alias JidoBuilderCore.{Agents, ApiKeys}

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "sse-test-#{System.unique_integer()}", slug: "sse-test-#{System.unique_integer()}"},
        "test"
      )

    {:ok, _api_key, raw_key} = ApiKeys.generate(workspace.id, "test-key", "test")

    %{workspace: workspace, raw_key: raw_key}
  end

  defp api_conn(conn, raw_key) do
    conn
    |> put_req_header("authorization", "Bearer #{raw_key}")
  end

  test "GET /mcp/sse returns SSE content-type", %{conn: conn, raw_key: key} do
    conn =
      conn
      |> api_conn(key)
      |> get(~p"/mcp/sse")

    assert get_resp_header(conn, "content-type") |> List.first() =~ "text/event-stream"
    assert conn.status == 200
  end

  test "GET /mcp/sse sends endpoint event with message URL", %{conn: conn, raw_key: key} do
    conn =
      conn
      |> api_conn(key)
      |> get(~p"/mcp/sse")

    body = conn.resp_body
    assert body =~ "event: endpoint"
    assert body =~ "/mcp/messages?session_id="
  end

  test "POST /mcp/messages with initialize returns JSON-RPC result", %{conn: conn, raw_key: key} do
    # First get a session_id from SSE
    sse_conn =
      conn
      |> api_conn(key)
      |> get(~p"/mcp/sse")

    # Extract session_id from the response
    [_, session_id] = Regex.run(~r/session_id=([a-f0-9\-]+)/, sse_conn.resp_body)

    msg_conn =
      conn
      |> api_conn(key)
      |> put_req_header("content-type", "application/json")
      |> post(~p"/mcp/messages?session_id=#{session_id}", %{
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: %{}
      })

    assert msg_conn.status == 200
    resp = json_response(msg_conn, 200)
    assert resp["jsonrpc"] == "2.0"
    assert resp["id"] == 1
    assert resp["result"]["protocolVersion"]
  end

  test "POST /mcp/messages with invalid session_id returns 404", %{conn: conn, raw_key: key} do
    conn =
      conn
      |> api_conn(key)
      |> put_req_header("content-type", "application/json")
      |> post(~p"/mcp/messages?session_id=nonexistent", %{
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: %{}
      })

    assert conn.status == 404
  end
end
