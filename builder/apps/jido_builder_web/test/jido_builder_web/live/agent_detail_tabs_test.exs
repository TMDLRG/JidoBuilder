defmodule JidoBuilderWeb.Live.AgentDetailTabsTest do
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "agent detail renders tab labels and json tree hook", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/agents/demo-agent")

    assert html =~ "Overview"
    assert html =~ "State Inspector"
    assert html =~ "Signal History"
    assert html =~ "Action Log"
    assert html =~ ~s(phx-hook="JsonTree")
  end
end
