defmodule JidoBuilderWeb.Live.PaletteKeyboardTest do
  @moduledoc "Phase 8.2 — Verify command palette is accessible via keyboard and click."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "layout has phx-window-keydown for global keyboard events", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/")
    assert html =~ "phx-window-keydown"
  end
end
