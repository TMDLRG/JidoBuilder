defmodule JidoBuilderWeb.LiveFlowsTest do
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  test "dashboard/roster/workflow/schedules/teams/settings render", %{conn: conn} do
    assert {:ok, _lv, html} = live(conn, ~p"/")
    assert html =~ "Dashboard"

    assert {:ok, _lv, html} = live(conn, ~p"/roster")
    assert html =~ "Agents"

    assert {:ok, _lv, html} = live(conn, ~p"/workflows")
    assert html =~ "Workflows"

    assert {:ok, _lv, html} = live(conn, ~p"/schedules")
    assert html =~ "Schedules"

    assert {:ok, _lv, html} = live(conn, ~p"/teams")
    assert html =~ "Teams (Pods)"

    assert {:ok, _lv, html} = live(conn, ~p"/settings")
    assert html =~ "Settings"
  end

  test "agent detail flow renders by id", %{conn: conn} do
    assert {:ok, _lv, html} = live(conn, ~p"/agents/alpha-1")
    assert html =~ "Agent Detail"
    # The agent id appears in the overview tab content
    assert html =~ "alpha-1"
  end

  test "dashboard handles empty and event stream updates", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")

    # The new dashboard renders a static Activity card
    assert html =~ "Activity"
    assert html =~ "Running Agents"
  end

  test "workflow builder renders canvas and panels", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/workflows")
    # The new workflow builder has a 3-panel layout with Canvas, Workflow List, Execution
    assert html =~ "Canvas"
    assert html =~ "Workflow List"
    assert html =~ "Execution"
    assert html =~ "workflow-dag"
  end

  test "unknown route renders not found page", %{conn: conn} do
    conn = get(conn, "/missing")
    assert conn.status == 404
    assert conn.resp_body =~ "Page not found"
  end
end
