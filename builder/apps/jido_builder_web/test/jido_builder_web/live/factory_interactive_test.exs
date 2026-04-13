defmodule JidoBuilderWeb.Live.FactoryInteractiveTest do
  @moduledoc "Phase 8.5 — Verify Factory page has deploy buttons."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "solution cards have deploy button with phx-click", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/factory")
    assert html =~ ~s(phx-click="deploy_solution")
  end

  test "clicking deploy shows result", %{conn: conn} do
    {:ok, lv, _html} = live(conn, "/factory")
    html = render_click(lv, "deploy_solution", %{"slug" => "help_desk"})
    assert html =~ "deployed" or html =~ "Deployed" or html =~ "agents"
  end
end
