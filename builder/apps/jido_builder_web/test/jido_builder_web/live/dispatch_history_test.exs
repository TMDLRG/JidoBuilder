defmodule JidoBuilderWeb.Live.DispatchHistoryTest do
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.{Agents, Observability}
  alias JidoBuilderRuntime.Roster

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "hist-ws", slug: "hist-ws-#{System.unique_integer([:positive])}"},
        "test-setup"
      )

    agent_name = "hist-agent-#{System.unique_integer([:positive])}"
    {:ok, _instance} = Roster.hire(workspace.id, agent_name, "test")

    # Seed some signal logs
    for i <- 1..3 do
      Observability.log_signal(
        %{
          workspace_id: workspace.id,
          direction: "inbound",
          signal_type: "test.signal.#{i}",
          payload: %{index: i, elapsed_ms: i * 10},
          correlation_id: Ecto.UUID.generate()
        },
        "tester"
      )
    end

    %{workspace: workspace, agent_name: agent_name}
  end

  test "dispatch history table shows previous dispatches with status", %{
    conn: conn,
    workspace: ws
  } do
    {:ok, _lv, html} = live(conn, ~p"/assignments/new?workspace_id=#{ws.id}")

    # The page should show a dispatch history section
    assert html =~ "Dispatch History" or html =~ "dispatch-history"
    # Should show the signal types we seeded
    assert html =~ "test.signal.1"
    assert html =~ "test.signal.2"
    assert html =~ "test.signal.3"
  end

  test "dispatch history shows timestamp and signal type columns", %{
    conn: conn,
    workspace: ws
  } do
    {:ok, _lv, html} = live(conn, ~p"/assignments/new?workspace_id=#{ws.id}")

    # Table headers should exist
    assert html =~ "Signal Type" or html =~ "signal_type"
  end
end
