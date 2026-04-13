defmodule JidoBuilderWeb.MCP.McpToolsComprehensiveTest do
  @moduledoc "Story 10.3 — MCP tools comprehensive testing."
  use JidoBuilderWeb.ConnCase, async: false

  alias JidoBuilderCore.{Agents, ApiKeys}

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "mcp-comp-#{System.unique_integer()}", slug: "mcp-comp-#{System.unique_integer()}"},
        "test"
      )

    {:ok, _api_key, raw_key} = ApiKeys.generate(workspace.id, "test-key", "test")
    %{workspace: workspace, raw_key: raw_key}
  end

  defp mcp_call(conn, raw_key, method, params \\ %{}) do
    conn
    |> put_req_header("authorization", "Bearer #{raw_key}")
    |> put_req_header("content-type", "application/json")
    |> post(~p"/mcp", %{jsonrpc: "2.0", id: 1, method: method, params: params})
    |> json_response(200)
  end

  test "initialize returns protocol version", %{conn: conn, raw_key: key} do
    resp = mcp_call(conn, key, "initialize")
    assert resp["result"]["protocolVersion"] == "2024-11-05"
    assert resp["result"]["serverInfo"]["name"] == "jido-builder"
  end

  test "tools/list returns all available tools", %{conn: conn, raw_key: key} do
    resp = mcp_call(conn, key, "tools/list")
    tools = resp["result"]["tools"]
    assert is_list(tools)
    assert length(tools) >= 6

    tool_names = Enum.map(tools, & &1["name"])
    assert "jido_agent" in tool_names
    assert "jido_template" in tool_names
    assert "jido_workflow" in tool_names
    assert "jido_observe" in tool_names
    assert "jido_help" in tool_names
  end

  test "jido_agent tool responds to help action", %{conn: conn, raw_key: key} do
    resp = mcp_call(conn, key, "tools/call", %{
      "name" => "jido_agent",
      "arguments" => %{"action" => "help"}
    })

    assert resp["result"]["isError"] == false
    content = hd(resp["result"]["content"])
    assert content["type"] == "text"
    assert String.length(content["text"]) > 0
  end

  test "jido_template tool responds to help action", %{conn: conn, raw_key: key} do
    resp = mcp_call(conn, key, "tools/call", %{
      "name" => "jido_template",
      "arguments" => %{"action" => "help"}
    })

    assert resp["result"]["isError"] == false
  end

  test "jido_observe tool responds to help action", %{conn: conn, raw_key: key} do
    resp = mcp_call(conn, key, "tools/call", %{
      "name" => "jido_observe",
      "arguments" => %{"action" => "help"}
    })

    assert resp["result"]["isError"] == false
  end

  test "jido_agent list returns agents", %{conn: conn, raw_key: key} do
    resp = mcp_call(conn, key, "tools/call", %{
      "name" => "jido_agent",
      "arguments" => %{"action" => "list"}
    })

    assert resp["result"]["isError"] == false
  end

  test "unknown tool returns error", %{conn: conn, raw_key: key} do
    resp = mcp_call(conn, key, "tools/call", %{
      "name" => "nonexistent_tool",
      "arguments" => %{}
    })

    assert resp["error"]["message"] =~ "Unknown tool"
  end

  test "notifications/initialized returns ok", %{conn: conn, raw_key: key} do
    resp = mcp_call(conn, key, "notifications/initialized")
    assert resp["result"] == %{}
  end

  test "unknown method returns error", %{conn: conn, raw_key: key} do
    resp = mcp_call(conn, key, "nonexistent/method")
    assert resp["error"]["message"] =~ "Method not found"
  end
end
