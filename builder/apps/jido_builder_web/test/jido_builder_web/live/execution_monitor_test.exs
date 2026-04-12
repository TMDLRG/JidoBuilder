defmodule JidoBuilderWeb.Live.ExecutionMonitorTest do
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated
  import Phoenix.LiveViewTest

  test "execution page renders timeline hook", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/execution")
    assert html =~ "Execution Monitor"
    assert html =~ ~s(phx-hook="ExecutionTimeline")
  end
end
