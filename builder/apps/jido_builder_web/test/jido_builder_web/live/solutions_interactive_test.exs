defmodule JidoBuilderWeb.Live.SolutionsInteractiveTest do
  @moduledoc "Phase 8.2 — Verify Solutions page deploy button works."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "deploy button has phx-click handler", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/solutions")
    assert html =~ ~s(phx-click="deploy")
  end

  test "clicking deploy shows deployment result", %{conn: conn} do
    {:ok, lv, _html} = live(conn, "/solutions")
    html = render_click(lv, "deploy", %{"slug" => "help_desk"})
    assert html =~ "deployed" or html =~ "Deployed" or html =~ "agent"
  end
end
