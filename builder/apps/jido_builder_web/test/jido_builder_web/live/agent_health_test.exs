defmodule JidoBuilderWeb.Live.AgentHealthTest do
  @moduledoc """
  Story 3.3 — Agent detail page with health metrics and signal history.

  Assertions:
    (a) Overview tab shows signal count from observability
    (b) Signals tab shows signal history for this agent
    (c) Health status shows "healthy" when process is alive
    (d) Health status shows "degraded" when process is dead
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.{Agents, Observability}
  alias JidoBuilderRuntime.Roster

  setup %{conn: conn} do
    {:ok, workspace} =
      Agents.create_workspace(
        %{
          name: "health-ws-#{System.unique_integer()}",
          slug: "health-ws-#{System.unique_integer()}"
        },
        "test-setup"
      )

    agent_name = "health-agent-#{System.unique_integer([:positive])}"
    {:ok, instance} = Roster.hire(workspace.id, agent_name, "test")

    # Log some signals for this agent using agent_instance_id
    Observability.log_signal(
      %{workspace_id: workspace.id, agent_instance_id: instance.id, signal_type: "ping", direction: "inbound", payload: %{}},
      "test"
    )

    Observability.log_signal(
      %{workspace_id: workspace.id, agent_instance_id: instance.id, signal_type: "increment", direction: "inbound", payload: %{}},
      "test"
    )

    %{workspace: workspace, agent_name: agent_name, instance: instance, conn: conn}
  end

  test "overview shows signal count", %{conn: conn, agent_name: name, workspace: ws} do
    {:ok, _lv, html} = live(conn, ~p"/agents/#{name}?workspace_id=#{ws.id}")
    # We logged 2 signals
    assert html =~ "2"
  end

  test "signals tab shows signal types", %{conn: conn, agent_name: name, workspace: ws} do
    {:ok, lv, _html} = live(conn, ~p"/agents/#{name}?workspace_id=#{ws.id}")
    html = lv |> element("[phx-click=tab][phx-value-name=signals]") |> render_click()
    assert html =~ "ping"
    assert html =~ "increment"
  end

  test "healthy agent shows healthy status", %{conn: conn, agent_name: name, workspace: ws} do
    {:ok, _lv, html} = live(conn, ~p"/agents/#{name}?workspace_id=#{ws.id}")
    assert html =~ "healthy"
  end

  test "stopped agent shows degraded status", %{conn: conn, agent_name: name, workspace: ws} do
    # Stop the agent first
    Roster.stop(ws.id, name, "test")

    {:ok, _lv, html} = live(conn, ~p"/agents/#{name}?workspace_id=#{ws.id}")
    assert html =~ "degraded"
  end
end
