defmodule JidoBuilderWeb.Live.MobileResponsiveTest do
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "layout renders without error at any viewport", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/")

    # Core layout elements present
    assert html =~ "app-sidebar"
    assert html =~ "app-shell"
    assert html =~ "Dashboard"
  end

  test "sidebar has responsive classes for mobile toggle", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/")

    # Sidebar should be hidden on mobile, visible on md+
    assert html =~ "hidden md:flex"
    # Mobile hamburger button should exist
    assert html =~ "mobile-menu-btn"
  end

  test "main content area uses responsive padding", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/")

    # Main content should have responsive padding
    assert html =~ "p-4 md:p-6"
  end

  test "header contains mobile menu toggle button", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/")

    # A visible-on-mobile toggle should exist in header
    assert html =~ "mobile-menu-btn"
  end
end
