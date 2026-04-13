defmodule JidoBuilderWeb.Api.V1.AgentControllerTest do
  @moduledoc """
  Story 4.2 — Agent CRUD API endpoint tests.

  Assertions:
    (a) POST /api/v1/agents creates agent and returns JSON
    (b) GET /api/v1/agents lists agents for workspace
    (c) GET /api/v1/agents/:id shows single agent
    (d) DELETE /api/v1/agents/:id stops agent
    (e) POST /api/v1/agents/:id/dispatch sends signal and returns result
  """
  use JidoBuilderWeb.ConnCase, async: false

  alias JidoBuilderCore.{Agents, ApiKeys}

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "agent-api-#{System.unique_integer()}", slug: "agent-api-#{System.unique_integer()}"},
        "test"
      )

    {:ok, _api_key, raw_key} = ApiKeys.generate(workspace.id, "test-key", "test")

    %{workspace: workspace, raw_key: raw_key}
  end

  defp api_conn(conn, raw_key) do
    conn
    |> put_req_header("authorization", "Bearer #{raw_key}")
    |> put_req_header("content-type", "application/json")
  end

  test "POST /api/v1/agents creates agent", %{conn: conn, raw_key: key} do
    name = "api-agent-#{System.unique_integer([:positive])}"

    conn =
      conn
      |> api_conn(key)
      |> post(~p"/api/v1/agents", %{name: name})

    assert %{"data" => %{"name" => ^name, "status" => "running"}} = json_response(conn, 201)
  end

  test "GET /api/v1/agents lists agents", %{conn: conn, raw_key: key, workspace: ws} do
    name = "list-agent-#{System.unique_integer([:positive])}"
    JidoBuilderRuntime.Roster.hire(ws.id, name, "test")

    conn =
      conn
      |> api_conn(key)
      |> get(~p"/api/v1/agents")

    assert %{"data" => agents} = json_response(conn, 200)
    assert is_list(agents)
    assert Enum.any?(agents, fn a -> a["name"] == name end)
  end

  test "GET /api/v1/agents/:id shows agent", %{conn: conn, raw_key: key, workspace: ws} do
    name = "show-agent-#{System.unique_integer([:positive])}"
    JidoBuilderRuntime.Roster.hire(ws.id, name, "test")

    conn =
      conn
      |> api_conn(key)
      |> get(~p"/api/v1/agents/#{name}")

    assert %{"data" => %{"name" => ^name}} = json_response(conn, 200)
  end

  test "GET /api/v1/agents/:id returns 404 for unknown", %{conn: conn, raw_key: key} do
    conn =
      conn
      |> api_conn(key)
      |> get(~p"/api/v1/agents/nonexistent-agent")

    assert json_response(conn, 404)["error"] =~ "not found"
  end

  test "DELETE /api/v1/agents/:id stops agent", %{conn: conn, raw_key: key, workspace: ws} do
    name = "stop-agent-#{System.unique_integer([:positive])}"
    JidoBuilderRuntime.Roster.hire(ws.id, name, "test")

    conn =
      conn
      |> api_conn(key)
      |> delete(~p"/api/v1/agents/#{name}")

    assert %{"data" => %{"status" => "stopped"}} = json_response(conn, 200)
  end

  test "POST /api/v1/agents/:id/dispatch dispatches signal", %{conn: conn, raw_key: key, workspace: ws} do
    name = "dispatch-agent-#{System.unique_integer([:positive])}"
    JidoBuilderRuntime.Roster.hire(ws.id, name, "test")

    conn =
      conn
      |> api_conn(key)
      |> post(~p"/api/v1/agents/#{name}/dispatch", %{signal_type: "ping", payload: %{message: "hello"}})

    assert %{"data" => %{"status" => "success"}} = json_response(conn, 200)
  end
end
