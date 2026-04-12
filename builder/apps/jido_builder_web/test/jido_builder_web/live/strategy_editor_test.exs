defmodule JidoBuilderWeb.Live.StrategyEditorTest do
  @moduledoc "Phase 5 — Strategy editor + FSM Designer."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated
  import Phoenix.LiveViewTest

  test "renders Strategy Editor heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/editor/strategy")
    assert html =~ "Strategy Editor"
  end

  test "preview strategy source", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/editor/strategy")

    html =
      lv
      |> form("#editor-form",
        block: %{module: "MyApp.DirectStrategy", name: "direct", description: "simple direct"}
      )
      |> render_submit()

    assert html =~ "defmodule" or html =~ "MyApp.DirectStrategy"
  end

  test "FSM states table renders", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/editor/strategy")
    assert html =~ "FSM" or html =~ "States"
  end
end
