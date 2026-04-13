defmodule JidoBuilderWeb.Live.TemplateLibraryInteractiveTest do
  @moduledoc "Phase 8.5 — Verify Template Library shows all actions, has search and skills tab."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "shows all actions, not truncated to 20", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/template-library")
    # Count occurrences of action card class
    count = html |> String.split("action-card") |> length()
    # Should have many more than 20
    assert count > 20
  end

  test "has search input with phx-change", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/template-library")
    assert html =~ ~s(phx-change="search")
  end

  test "searching filters displayed actions", %{conn: conn} do
    {:ok, lv, _html} = live(conn, "/template-library")
    html = render_change(lv, "search", %{"q" => "echo"})
    assert html =~ "Echo"
  end

  test "has Skills tab", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/template-library")
    assert html =~ "Skills" or html =~ "skills"
  end

  test "category filter works", %{conn: conn} do
    {:ok, lv, _html} = live(conn, "/template-library")
    html = render_click(lv, "filter_category", %{"cat" => "utility"})
    assert html =~ "Echo"
  end
end
