defmodule JidoBuilderWeb.Live.PoolsTest do
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated
  import Phoenix.LiveViewTest

  test "renders pool config", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/pools")
    assert html =~ "Pools"
    assert html =~ "default_pool"
  end

  test "update pool size", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/pools")

    html =
      lv
      |> form("#pool-config-form", pool: %{name: "default_pool", size: "9", max_overflow: "3"})
      |> render_submit()

    assert html =~ "Pool config updated"
    assert html =~ "9"
  end
end
