defmodule JidoBuilderWeb.Live.AppShellTest do
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "app shell renders grouped sidebar links", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/")

    assert html =~ "OPERATE"
    assert html =~ "CONFIGURE"
    assert html =~ "OBSERVE"
    assert html =~ "ADMIN"
    assert html =~ "Dashboard"
    assert html =~ "Agents"
    assert html =~ "Execution"
    assert html =~ ~s(href="/execution")
  end

  test "sidebar/header exist on non-dashboard pages", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/roster")
    assert html =~ "Toggle"
    assert html =~ "Workspaces"
  end
end
