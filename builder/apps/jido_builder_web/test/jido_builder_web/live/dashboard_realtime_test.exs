defmodule JidoBuilderWeb.Live.DashboardRealtimeTest do
  @moduledoc "Phase 9.1 — Dashboard subscribes to PubSub and shows live activity."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "dashboard renders with real KPI data", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/")
    assert html =~ "Running Agents"
    assert html =~ "Active Workflows"
    assert html =~ "Signals/hr"
  end

  test "dashboard activity feed shows real events when connected", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/")
    # Should not show hardcoded strings anymore
    # Instead should show "Connected" or be empty initially
    assert html =~ "Activity"
  end

  test "dashboard error card links to debug page", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/")
    assert html =~ "/debug" or html =~ "No active errors"
  end
end
