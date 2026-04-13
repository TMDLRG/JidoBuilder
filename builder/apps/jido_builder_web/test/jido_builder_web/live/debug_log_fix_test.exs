defmodule JidoBuilderWeb.Live.DebugLogFixTest do
  @moduledoc "Phase 8.1 — Verify debug page renders logs using direction field (not log_type)."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.{Repo, Observability.SignalLog, Agents.Workspace}

  setup do
    # Ensure workspace exists
    ws =
      case Repo.get_by(Workspace, slug: "agent-lab") do
        nil ->
          {:ok, ws} = Repo.insert(%Workspace{name: "Agent Lab", slug: "agent-lab", metadata: %{}})
          ws

        ws ->
          ws
      end

    # Insert a signal log entry so the log stream has data
    {:ok, _log} =
      Repo.insert(%SignalLog{
        workspace_id: ws.id,
        direction: "inbound",
        signal_type: "ping",
        payload: %{},
        correlation_id: "test-#{System.unique_integer([:positive])}"
      })

    {:ok, workspace: ws}
  end

  test "debug page renders without crash when signal logs exist", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/debug")
    assert html =~ "Debug"
    assert html =~ "Log Stream"
  end

  test "debug page displays direction field in log badge", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/debug")
    assert html =~ "inbound"
  end
end
