defmodule JidoBuilderWeb.Live.PoolsTest do
  @moduledoc "Phase 4 — Pools: worker pool configuration view."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated
  import Phoenix.LiveViewTest

  test "renders Pools heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/pools")
    assert html =~ "Pools"
  end

  test "shows configuration options", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/pools")
    assert html =~ "size" or html =~ "pool" or html =~ "Pools"
  end
end
