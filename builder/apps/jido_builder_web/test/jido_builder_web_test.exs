defmodule JidoBuilderWeb.LiveFlowsTest do
  use JidoBuilderWeb.ConnCase, async: false

  alias JidoBuilderRuntime.EventBus

  test "dashboard/roster/workflow/schedules/teams/settings render", %{conn: conn} do
    assert {:ok, _lv, html} = live(conn, ~p"/")
    assert html =~ "Home Dashboard"

    assert {:ok, _lv, html} = live(conn, ~p"/roster")
    assert html =~ "Roster / Hire Wizard"

    assert {:ok, _lv, html} = live(conn, ~p"/workflows")
    assert html =~ "Workflow Builder"

    assert {:ok, _lv, html} = live(conn, ~p"/schedules")
    assert html =~ "Schedules"

    assert {:ok, _lv, html} = live(conn, ~p"/teams")
    assert html =~ "Teams (Pods)"

    assert {:ok, _lv, html} = live(conn, ~p"/settings")
    assert html =~ "Settings"
  end

  test "agent detail flow renders by id", %{conn: conn} do
    assert {:ok, _lv, html} = live(conn, ~p"/agents/alpha-1")
    assert html =~ "Viewing agent alpha-1"
    assert html =~ "Agent Event Stream"
  end

  test "dashboard handles empty and event stream updates", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Workspace Activity"
    refute html =~ "hire.start"

    Phoenix.PubSub.broadcast(
      JidoBuilder.PubSub,
      EventBus.workspace_activity_topic(1),
      {:jido_event, %{id: "evt-1", event_name: "hire.start", status: "ok"}}
    )

    assert render(view) =~ "hire.start"
  end

  test "workflow stream renders loading/empty and update", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/workflows")
    assert html =~ "Workflow Execution Stream"
    refute html =~ "workflow.complete"

    Phoenix.PubSub.broadcast(
      JidoBuilder.PubSub,
      EventBus.workflow_activity_topic(1),
      {:jido_event, %{id: "wf-1", event_name: "workflow.complete", status: "ok"}}
    )

    assert render(view) =~ "workflow.complete"
  end

  test "unknown route renders not found page", %{conn: conn} do
    assert_error_sent(404, fn -> get(conn, "/missing") end)
  end
end
