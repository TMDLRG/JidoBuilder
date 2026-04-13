defmodule JidoBuilderWeb.Live.NotebookInteractiveTest do
  @moduledoc "Phase 8.1 — Verify notebook run_cell event works end-to-end."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "run_cell event executes code and renders result", %{conn: conn} do
    {:ok, lv, _html} = live(conn, "/notebook")

    # Push the run_cell event (simulating what CodeEditor hook sends)
    html = render_click(lv, "run_cell", %{"code" => "1 + 1"})
    assert html =~ "2"
  end

  test "run_cell accumulates multiple cell results", %{conn: conn} do
    {:ok, lv, _html} = live(conn, "/notebook")

    render_click(lv, "run_cell", %{"code" => "x = 10"})
    html = render_click(lv, "run_cell", %{"code" => "x * 3"})

    # Both cells should be visible
    assert html =~ "Cell 1"
    assert html =~ "Cell 2"
  end

  test "run_cell handles errors gracefully", %{conn: conn} do
    {:ok, lv, _html} = live(conn, "/notebook")

    html = render_click(lv, "run_cell", %{"code" => "1 / 0"})

    # Should show error, not crash
    assert html =~ "error" or html =~ "Error" or html =~ "ArithmeticError"
  end
end
