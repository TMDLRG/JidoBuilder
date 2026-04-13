defmodule JidoBuilderWeb.Live.DispatchLiveTest do
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.Agents
  alias JidoBuilderRuntime.Roster

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "dispatch-ws", slug: "dispatch-ws-#{System.unique_integer([:positive])}"},
        "test-setup"
      )

    agent_name = "dispatch-agent-#{System.unique_integer([:positive])}"
    {:ok, _instance} = Roster.hire(workspace.id, agent_name, "test")

    %{workspace: workspace, agent_name: agent_name}
  end

  test "sync dispatch shows elapsed time in result panel", %{
    conn: conn,
    workspace: ws,
    agent_name: agent_name
  } do
    {:ok, lv, _html} = live(conn, ~p"/assignments/new?workspace_id=#{ws.id}")

    # Pick the agent
    lv |> element("button[phx-value-id=\"#{agent_name}\"]") |> render_click()

    # Submit the dispatch form (sync mode is default)
    html =
      lv
      |> form("#dispatch-form", %{
        "dispatch" => %{"signal_type" => "ping", "payload" => "{}"}
      })
      |> render_submit()

    # Should show execution result with timing, not "dispatched async"
    refute html =~ "dispatched async"
    # Should show elapsed time in ms
    assert html =~ "ms"
  end

  test "dispatch form renders with mode toggle", %{conn: conn, workspace: ws} do
    {:ok, _lv, html} = live(conn, ~p"/assignments/new?workspace_id=#{ws.id}")

    assert html =~ "Dispatch Signal"
    assert html =~ "dispatch-form"
    assert html =~ "Sync"
  end

  test "mode toggle switches between sync and async", %{conn: conn, workspace: ws} do
    {:ok, lv, html} = live(conn, ~p"/assignments/new?workspace_id=#{ws.id}")

    assert html =~ "Sync"

    html = lv |> element("button[phx-click=\"toggle_mode\"]") |> render_click()
    assert html =~ "Async"

    html = lv |> element("button[phx-click=\"toggle_mode\"]") |> render_click()
    assert html =~ "Sync"
  end
end
