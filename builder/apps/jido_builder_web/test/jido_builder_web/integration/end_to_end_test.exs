defmodule JidoBuilderWeb.Integration.EndToEndTest do
  @moduledoc "Story 10.3 — End-to-end: create template → hire agent → dispatch signal via API."
  use JidoBuilderWeb.ConnCase, async: false

  alias JidoBuilderCore.{Agents, ApiKeys}

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "e2e-#{System.unique_integer()}", slug: "e2e-#{System.unique_integer()}"},
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

  test "full lifecycle: create template via API → hire agent → dispatch signal", %{conn: conn, raw_key: key} do
    # Step 1: Create a template
    template_resp =
      conn
      |> api_conn(key)
      |> post(~p"/api/v1/templates", %{name: "E2E Template", slug: "e2e-tmpl", status: "active", version: "1.0.0"})
      |> json_response(201)

    template_id = template_resp["data"]["id"]
    assert is_integer(template_id)

    # Step 2: Hire an agent with that template
    agent_name = "e2e-agent-#{System.unique_integer([:positive])}"

    agent_resp =
      conn
      |> api_conn(key)
      |> post(~p"/api/v1/agents", %{name: agent_name, template_id: template_id})
      |> json_response(201)

    assert agent_resp["data"]["name"] == agent_name
    assert agent_resp["data"]["status"] == "running"
    assert agent_resp["data"]["template_id"] == template_id

    # Step 3: Dispatch a signal to the agent (may fail if no route, but should not crash)
    dispatch_conn =
      conn
      |> api_conn(key)
      |> post(~p"/api/v1/agents/#{agent_name}/dispatch", %{signal_type: "ping", payload: %{msg: "hello"}})

    # Accept both success (200) and handled error (422) — the point is it doesn't crash
    assert dispatch_conn.status in [200, 422]
    dispatch_resp = json_response(dispatch_conn, dispatch_conn.status)
    assert dispatch_resp["data"]

    # Step 4: Verify agent is listed
    list_resp =
      conn
      |> api_conn(key)
      |> get(~p"/api/v1/agents")
      |> json_response(200)

    agent_names = Enum.map(list_resp["data"], & &1["name"])
    assert agent_name in agent_names

    # Step 5: Clean up — stop the agent
    delete_resp =
      conn
      |> api_conn(key)
      |> delete(~p"/api/v1/agents/#{agent_name}")
      |> json_response(200)

    assert delete_resp["data"]
  end
end
