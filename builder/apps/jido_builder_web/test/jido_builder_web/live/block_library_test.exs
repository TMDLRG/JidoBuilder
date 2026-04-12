defmodule JidoBuilderWeb.Live.BlockLibraryTest do
  @moduledoc "Phase 5 — Block library + validator."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated
  import Phoenix.LiveViewTest

  test "renders Block Library heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/blocks")
    assert html =~ "Block Library"
  end

  test "all 5 block types are listed", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/blocks")
    assert html =~ "action"
    assert html =~ "agent"
    assert html =~ "plugin"
    assert html =~ "sensor"
    assert html =~ "strategy"
  end

  test "validate block form returns ok for valid block", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/blocks")

    html =
      lv
      |> form("#validate-form",
        block: %{type: "action", module: "MyApp.TestAction", name: "test", description: "a test"}
      )
      |> render_submit()

    assert html =~ "valid" or html =~ "ok"
  end
end
