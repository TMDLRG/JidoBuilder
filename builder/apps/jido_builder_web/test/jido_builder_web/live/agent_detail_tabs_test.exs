defmodule JidoBuilderWeb.Live.AgentDetailTabsTest do
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "agent detail renders tab labels and json tree hook", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/agents/demo-agent")

    # Tab labels rendered (lowercase in the <.tabs> component, title-case in buttons)
    assert html =~ "overview"
    assert html =~ "State Inspector"
    assert html =~ "Signal History"
    assert html =~ "Action Log"

    # JsonTree hook is on the state tab — click it first
    html = lv |> element("button", "State Inspector") |> render_click()
    assert html =~ ~s(phx-hook="JsonTree")
  end
end
