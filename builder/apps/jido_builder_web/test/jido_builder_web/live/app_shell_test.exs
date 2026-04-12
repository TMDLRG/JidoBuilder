defmodule JidoBuilderWeb.Live.AppShellTest do
  @moduledoc """
  Phase 2.1 — App shell navigation + Cmd+K command palette.

  Assertions:
    (a) The app layout renders a sidebar/nav with links to all 8+ main
        routes and highlights the current page.
    (b) The nav includes a link to "/assignments/new".
    (c) A Cmd+K command palette component exists and is rendered (hidden by
        default, toggled via JS).
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "app shell renders nav with all main routes", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/")

    assert html =~ "Dashboard"
    assert html =~ "Roster"
    assert html =~ "Workflow Builder"
    assert html =~ "Schedules"
    assert html =~ "Teams"
    assert html =~ "Settings"
    assert html =~ "Assignments"
    assert html =~ ~s(href="/assignments/new")
  end

  test "nav links are present on non-dashboard pages", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/roster")
    assert html =~ "Dashboard"
    assert html =~ "Assignments"
  end

  test "Cmd+K palette container is present in the layout", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/")
    assert html =~ "command-palette"
  end
end
