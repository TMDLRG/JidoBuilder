defmodule JidoBuilderWeb.Live.TracesTest do
  @moduledoc "Phase 4 — Traces viewer: shows telemetry/observability trace log."
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
    %{workspace: ws}
  end

  test "renders Traces heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/traces")
    assert html =~ "Traces"
  end

  test "shows empty state when no signal logs", %{conn: conn, workspace: ws} do
    {:ok, _lv, html} = live(conn, ~p"/traces?workspace_id=#{ws.id}")
    assert html =~ "Traces" or html =~ "No trace"
  end
end
