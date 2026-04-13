defmodule JidoBuilderWeb.Live.AgentLifecycleTest do
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "agent lifecycle pages expose hire/dispatch/stop surfaces", %{conn: conn} do
    {:ok, _roster, roster_html} = live(conn, ~p"/roster")
    assert roster_html =~ "Hire"

    {:ok, _dispatch, dispatch_html} = live(conn, ~p"/assignments/new")
    assert dispatch_html =~ "Dispatch"

    {:ok, _agent, agent_html} = live(conn, ~p"/agents/demo-agent")
    assert agent_html =~ "State"
  end
end
