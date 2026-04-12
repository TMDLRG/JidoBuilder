defmodule JidoBuilderWeb.Live.TracesTest do
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated

  import Phoenix.LiveViewTest
  alias JidoBuilderCore.{Agents, Observability}

  setup do
    {:ok, ws} =
      Agents.create_workspace(
        %{name: "trace-ws-#{System.unique_integer()}", slug: "trace-#{System.unique_integer()}"},
        "test"
      )

    {:ok, _} =
      Observability.log_signal(
        %{workspace_id: ws.id, direction: "outbound", signal_type: "ping", payload: %{}},
        "test"
      )

    %{workspace: ws}
  end

  test "filter by signal type", %{conn: conn, workspace: ws} do
    {:ok, lv, _html} = live(conn, ~p"/traces?workspace_id=#{ws.id}")
    html = lv |> form("#trace-filter-form", filter: %{signal_type: "ping"}) |> render_change()
    assert html =~ "ping"
  end

  test "shows trace detail", %{conn: conn, workspace: ws} do
    {:ok, lv, _html} = live(conn, ~p"/traces?workspace_id=#{ws.id}")
    html = lv |> element("#trace-signals-list button") |> render_click()
    assert html =~ "trace-detail"
  end
end
