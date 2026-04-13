defmodule JidoBuilderWeb.MCP.GuideTest do
  @moduledoc """
  Story 5.3 — AI Agent Guide + Story 5.4 basic notification support.
  """
  use JidoBuilderWeb.ConnCase, async: false

  alias JidoBuilderCore.{Agents, ApiKeys}

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "guide-ws-#{System.unique_integer()}", slug: "guide-ws-#{System.unique_integer()}"},
        "test"
      )
    {:ok, _, raw_key} = ApiKeys.generate(workspace.id, "guide-key", "test")
    %{workspace: workspace, raw_key: raw_key}
  end

  defp mcp_call(conn, key, method, params \\ %{}) do
    conn
    |> put_req_header("authorization", "Bearer #{key}")
    |> put_req_header("content-type", "application/json")
    |> post(~p"/mcp", %{jsonrpc: "2.0", id: 1, method: method, params: params})
  end

  test "jido_help guide returns comprehensive guide", %{conn: conn, raw_key: key} do
    conn = mcp_call(conn, key, "tools/call", %{name: "jido_help", arguments: %{action: "guide"}})
    resp = json_response(conn, 200)
    text = hd(resp["result"]["content"])["text"]
    assert text =~ "JidoBuilder"
    assert text =~ "Quick Start"
    # v2 tools must be listed
    assert text =~ "jido_factory"
    assert text =~ "jido_llm"
    assert text =~ "jido_active_inference"
    assert text =~ "jido_notebook"
    assert text =~ "jido_library"
    assert text =~ "jido_solution"
    assert text =~ "jido_skill"
  end

  test "jido_help tool_help returns schema for specific tool", %{conn: conn, raw_key: key} do
    conn = mcp_call(conn, key, "tools/call", %{name: "jido_help", arguments: %{action: "tool_help", tool: "jido_agent"}})
    resp = json_response(conn, 200)
    text = hd(resp["result"]["content"])["text"]
    assert text =~ "jido_agent"
    assert text =~ "action"
  end

  test "jido_help glossary returns terminology", %{conn: conn, raw_key: key} do
    conn = mcp_call(conn, key, "tools/call", %{name: "jido_help", arguments: %{action: "glossary"}})
    resp = json_response(conn, 200)
    text = hd(resp["result"]["content"])["text"]
    assert text =~ "Agent"
    assert text =~ "Signal"
    assert text =~ "Template"
    # v2 terms
    assert text =~ "Active Inference"
    assert text =~ "Notebook"
    assert text =~ "Factory"
    assert text =~ "Skill"
    assert text =~ "LLM Provider"
    assert text =~ "Generative Model"
  end

  test "jido_help examples returns workflow examples", %{conn: conn, raw_key: key} do
    conn = mcp_call(conn, key, "tools/call", %{name: "jido_help", arguments: %{action: "examples"}})
    resp = json_response(conn, 200)
    text = hd(resp["result"]["content"])["text"]
    assert text =~ "hire"
    assert text =~ "dispatch"
    # v2 examples
    assert text =~ "jido_active_inference"
    assert text =~ "jido_solution"
  end

  test "tool with no params returns help text", %{conn: conn, raw_key: key} do
    conn = mcp_call(conn, key, "tools/call", %{name: "jido_agent", arguments: %{}})
    resp = json_response(conn, 200)
    text = hd(resp["result"]["content"])["text"]
    assert text =~ "jido_agent"
  end
end
