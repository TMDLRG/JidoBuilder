defmodule JidoBuilderWeb.Live.DashboardActivityTest do
  @moduledoc """
  Phase 1.3 — Activity stream with plain-language rows.

  Verifies that `Observability.translate_event/1` turns raw Jido telemetry
  metadata into a human-readable label and that `DashboardLive` renders
  that label (not the raw event name) when displaying stream rows.
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.Observability

  describe "translate_event/1" do
    test "cmd.stop success maps to readable label" do
      meta = %{
        event: [:jido, :agent, :cmd, :stop],
        event_name: "jido.agent.cmd.stop",
        kind: "cmd",
        status: "stop",
        agent_id: "test-agent-1",
        workspace_id: 1,
        duration_native: 1_000_000,
        metadata: %{action: "ping"}
      }

      result = Observability.translate_event(meta)

      assert %{label: label, status: status, agent_link: link} = result
      assert is_binary(label)
      assert label =~ "test-agent-1"
      refute label =~ "jido.agent.cmd.stop"
      assert status in [:success, :error, :running, :unknown]
      assert link == "/agents/test-agent-1"
    end

    test "cmd.exception maps to error status with next_hint" do
      meta = %{
        event: [:jido, :agent, :cmd, :exception],
        event_name: "jido.agent.cmd.exception",
        kind: "cmd",
        status: "exception",
        agent_id: "failing-agent",
        workspace_id: 1,
        duration_native: nil,
        metadata: %{error: "timeout"}
      }

      result = Observability.translate_event(meta)

      assert result.status == :error
      assert is_binary(result.next_hint)
      assert result.next_hint != ""
    end
  end

  describe "DashboardLive activity stream" do
    test "broadcasts translate to readable labels in the stream",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      raw_event = %{
        id: System.unique_integer([:positive, :monotonic]),
        event: [:jido, :agent, :cmd, :stop],
        event_name: "jido.agent.cmd.stop",
        kind: "cmd",
        status: "stop",
        agent_id: "broadcast-agent",
        workspace_id: 1,
        duration_native: 500_000,
        metadata: %{action: "run"},
        measured_at: DateTime.utc_now()
      }

      Phoenix.PubSub.broadcast(
        JidoBuilder.PubSub,
        "workspace:1:activity",
        {:jido_event, raw_event}
      )

      # Give the LV time to process the broadcast
      Process.sleep(50)
      html = render(view)

      # Should NOT render the raw event name verbatim; should render translated label
      refute html =~ "jido.agent.cmd.stop"
      assert html =~ "broadcast-agent"
    end
  end
end
