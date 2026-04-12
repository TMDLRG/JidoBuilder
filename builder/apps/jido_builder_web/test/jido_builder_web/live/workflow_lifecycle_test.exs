defmodule JidoBuilderWeb.Live.WorkflowLifecycleTest do
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "workflow builder exposes list, canvas, and config panel", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/workflows")

    assert html =~ "Workflow List"
    assert html =~ "Canvas"
    assert html =~ "Node Config"
    assert html =~ ~s(phx-hook="WorkflowDag")
  end
end
