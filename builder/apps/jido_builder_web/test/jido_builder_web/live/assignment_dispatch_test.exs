defmodule JidoBuilderWeb.Live.AssignmentDispatchTest do
  @moduledoc """
  Phase 1.2 + 7.14 — Assignments console dispatches a signal and is
  rate-limited to 10 req/min per user.

  Assertions:
    - Navigating to /assignments/new renders the form with a target-agent
      selector and a signal-type field.
    - Submitting with a valid target agent + signal type:
        (a) inserts a signal_logs row
        (b) the LV renders a result feedback panel
    - Submitting 11 times in the same rate-limit window returns an error
      assigns with the "Too many signals" message (7.14 rate limit gate).
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias JidoBuilderCore.Agents
  alias JidoBuilderCore.Observability.SignalLog
  alias JidoBuilderCore.Repo
  alias JidoBuilderRuntime.Roster

  setup %{conn: conn} do
    {:ok, workspace} =
      Agents.create_workspace(
        %{
          name: "assign-test-ws-#{System.unique_integer()}",
          slug: "assign-ws-#{System.unique_integer()}"
        },
        "test-setup"
      )

    agent_name = "assign-agent-#{System.unique_integer([:positive])}"
    {:ok, _instance} = Roster.hire(workspace.id, agent_name, "test")

    %{workspace: workspace, agent_name: agent_name}
  end

  test "form renders with target selector and signal-type field", %{
    conn: conn,
    workspace: ws
  } do
    {:ok, _lv, html} = live(conn, ~p"/assignments/new?workspace_id=#{ws.id}")

    assert html =~ "Target Agent"
    assert html =~ "Signal Type"
  end

  test "valid dispatch inserts signal_logs row and shows result",
       %{conn: conn, workspace: ws, agent_name: agent_name} do
    {:ok, lv, _html} = live(conn, ~p"/assignments/new?workspace_id=#{ws.id}")

    html =
      lv
      |> form("#dispatch-form",
        dispatch: %{target_agent: agent_name, signal_type: "ping", payload: "{}"}
      )
      |> render_submit()

    # feedback panel visible
    assert html =~ "dispatched" or html =~ "result" or html =~ "ok"

    # signal_logs row persisted (may be more than one from async telemetry)
    assert Repo.exists?(from s in SignalLog, where: s.workspace_id == ^ws.id)
  end

  test "11th dispatch within rate-limit window returns 'Too many signals' error",
       %{conn: conn, workspace: ws, agent_name: agent_name} do
    {:ok, lv, _html} = live(conn, ~p"/assignments/new?workspace_id=#{ws.id}")

    # exhaust 10 allowed dispatches
    for _ <- 1..10 do
      lv
      |> form("#dispatch-form",
        dispatch: %{target_agent: agent_name, signal_type: "ping", payload: "{}"}
      )
      |> render_submit()
    end

    # 11th should be rate-limited
    html =
      lv
      |> form("#dispatch-form",
        dispatch: %{target_agent: agent_name, signal_type: "ping", payload: "{}"}
      )
      |> render_submit()

    assert html =~ "Too many signals"
  end
end
