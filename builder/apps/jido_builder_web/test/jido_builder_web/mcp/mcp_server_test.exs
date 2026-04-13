defmodule JidoBuilderWeb.MCP.ServerTest do
  @moduledoc """
  Story 5.1 — MCP server foundation.

  Assertions:
    (a) POST /mcp with initialize request returns capabilities
    (b) POST /mcp with tools/list returns all registered tools
    (c) POST /mcp with tools/call on jido_agent list action returns agents
    (d) POST /mcp with unknown method returns method_not_found error
    (e) ToolRegistry.list/0 returns all MCP tools with schemas
  """
  use JidoBuilderWeb.ConnCase, async: false

  alias JidoBuilderCore.{Agents, ApiKeys}
  alias JidoBuilderWeb.MCP.ToolRegistry

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "mcp-ws-#{System.unique_integer()}", slug: "mcp-ws-#{System.unique_integer()}"},
        "test"
      )

    {:ok, _api_key, raw_key} = ApiKeys.generate(workspace.id, "mcp-key", "test")

    %{workspace: workspace, raw_key: raw_key}
  end

  defp mcp_call(conn, key, method, params \\ %{}) do
    body = %{
      jsonrpc: "2.0",
      id: System.unique_integer([:positive]),
      method: method,
      params: params
    }

    conn
    |> put_req_header("authorization", "Bearer #{key}")
    |> put_req_header("content-type", "application/json")
    |> post(~p"/mcp", body)
  end

  test "initialize returns server capabilities", %{conn: conn, raw_key: key} do
    conn = mcp_call(conn, key, "initialize", %{
      protocolVersion: "2024-11-05",
      capabilities: %{},
      clientInfo: %{name: "test", version: "1.0"}
    })

    resp = json_response(conn, 200)
    assert resp["result"]["protocolVersion"] == "2024-11-05"
    assert resp["result"]["serverInfo"]["name"] == "jido-builder"
    assert is_map(resp["result"]["capabilities"])
  end

  test "tools/list returns registered tools", %{conn: conn, raw_key: key} do
    conn = mcp_call(conn, key, "tools/list")

    resp = json_response(conn, 200)
    tools = resp["result"]["tools"]
    assert is_list(tools)
    assert length(tools) >= 5

    names = Enum.map(tools, & &1["name"])
    assert "jido_agent" in names
    assert "jido_template" in names
    assert "jido_workflow" in names
    assert "jido_observe" in names
    assert "jido_help" in names
  end

  test "tools/call on jido_agent with list action returns agents", %{conn: conn, raw_key: key, workspace: ws} do
    JidoBuilderRuntime.Roster.hire(ws.id, "mcp-test-agent-#{System.unique_integer([:positive])}", "test")

    conn = mcp_call(conn, key, "tools/call", %{
      name: "jido_agent",
      arguments: %{action: "list"}
    })

    resp = json_response(conn, 200)
    assert is_list(resp["result"]["content"])
    content = hd(resp["result"]["content"])
    assert content["type"] == "text"
  end

  test "unknown method returns error", %{conn: conn, raw_key: key} do
    conn = mcp_call(conn, key, "nonexistent/method")

    resp = json_response(conn, 200)
    assert resp["error"]["code"] == -32601
  end

  test "ToolRegistry.list/0 returns all tools with schemas" do
    tools = ToolRegistry.list()
    assert is_list(tools)
    assert length(tools) >= 5

    tool = Enum.find(tools, fn t -> t.name == "jido_agent" end)
    assert tool
    assert is_map(tool.input_schema)
    assert tool.description
  end
end
