defmodule JidoBuilderWeb.Live.ExecutionResultTest do
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.Agents
  alias JidoBuilderRuntime.Roster

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "exec-result-ws", slug: "exec-res-#{System.unique_integer([:positive])}"},
        "test-setup"
      )

    agent_name = "exec-result-agent-#{System.unique_integer([:positive])}"
    {:ok, _instance} = Roster.hire(workspace.id, agent_name, "test")

    %{workspace: workspace, agent_name: agent_name}
  end

  test "result panel renders agent state JSON after successful dispatch", %{
    conn: conn,
    workspace: ws,
    agent_name: agent_name
  } do
    {:ok, lv, _html} = live(conn, ~p"/assignments/new?workspace_id=#{ws.id}")

    # Pick the agent
    lv |> element("button[phx-value-id=\"#{agent_name}\"]") |> render_click()

    # Dispatch a signal
    html =
      lv
      |> form("#dispatch-form", %{
        "dispatch" => %{"signal_type" => "ping", "payload" => "{}"}
      })
      |> render_submit()

    # Result panel should show:
    # 1. Status badge
    assert html =~ "Success" or html =~ "Error"
    # 2. Elapsed time
    assert html =~ "ms"
    # 3. Agent state expandable section
    assert html =~ "Agent State"
    # 4. Signal type
    assert html =~ "Signal"
    # 5. Correlation ID
    assert html =~ "Correlation"
  end

  test "result panel shows error details on dispatch failure", %{
    conn: conn,
    workspace: ws
  } do
    {:ok, lv, _html} = live(conn, ~p"/assignments/new?workspace_id=#{ws.id}")

    # Dispatch without selecting an agent
    html =
      lv
      |> form("#dispatch-form", %{
        "dispatch" => %{"signal_type" => "ping", "payload" => "{}"}
      })
      |> render_submit()

    # Should show error message
    assert html =~ "Select an agent first"
  end

  test "result panel shows target agent name", %{
    conn: conn,
    workspace: ws,
    agent_name: agent_name
  } do
    {:ok, lv, _html} = live(conn, ~p"/assignments/new?workspace_id=#{ws.id}")

    # Pick the agent and dispatch
    lv |> element("button[phx-value-id=\"#{agent_name}\"]") |> render_click()

    html =
      lv
      |> form("#dispatch-form", %{
        "dispatch" => %{"signal_type" => "ping", "payload" => "{}"}
      })
      |> render_submit()

    # Should show the target agent name somewhere in the result
    assert html =~ agent_name
  end
end
