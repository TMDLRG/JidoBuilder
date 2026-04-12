defmodule JidoBuilderWeb.Live.DirectivesBuilderTest do
  @moduledoc "Phase 2.8 — Directives builder renders all directive types."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "directives page renders heading and directive type list", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/directives")
    assert html =~ "Directives Builder"
    assert html =~ "Emit"
    assert html =~ "Stop"
  end
end
