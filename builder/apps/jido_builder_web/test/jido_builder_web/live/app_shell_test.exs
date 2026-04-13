defmodule JidoBuilderWeb.Live.AppShellTest do
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "app shell renders all sidebar sections", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/")

    # All 7 sections present
    assert html =~ "Operate"
    assert html =~ "Configure"
    assert html =~ "Build"
    assert html =~ "Observe"
    assert html =~ "Admin"
    assert html =~ "Help"

    # Critical nav items present
    assert html =~ "Dashboard"
    assert html =~ "Agents"
    assert html =~ "Dispatch Signal"
    assert html =~ "Workflows"
    assert html =~ "Execution"
    assert html =~ "User Guide"
    assert html =~ ~s(href="/assignments/new")
    assert html =~ ~s(href="/execution")
  end

  test "sidebar/header exist on non-dashboard pages", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/roster")
    assert html =~ "sidebar-toggle"
    assert html =~ "Workspaces"
  end
end
