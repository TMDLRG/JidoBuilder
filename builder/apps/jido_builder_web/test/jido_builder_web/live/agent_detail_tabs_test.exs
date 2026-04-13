defmodule JidoBuilderWeb.Live.AgentDetailTabsTest do
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "agent detail renders tab labels and json tree hook", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/agents/demo-agent")

    # Tab labels rendered
    assert html =~ "Overview"
    assert html =~ "State"
    assert html =~ "Signals"
    assert html =~ "Actions"

    # JsonTree hook is on the state tab — click it first
    html = lv |> element("[phx-click=tab][phx-value-name=state]") |> render_click()
    assert html =~ ~s(phx-hook="JsonTree")
  end
end
