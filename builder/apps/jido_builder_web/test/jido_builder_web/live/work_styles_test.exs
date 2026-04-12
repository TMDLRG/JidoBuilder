defmodule JidoBuilderWeb.Live.WorkStylesTest do
  @moduledoc "Phase 2.7 — Work Styles picker renders strategy options."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "work styles page renders heading and strategy options", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/work-styles")
    assert html =~ "Work Styles"
    assert html =~ "Direct" or html =~ "Strategy"
  end
end
