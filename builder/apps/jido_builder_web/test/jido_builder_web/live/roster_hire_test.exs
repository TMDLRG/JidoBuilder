defmodule JidoBuilderWeb.Live.RosterHireTest do
  @moduledoc """
  Phase 1.1 — Roster hire truth path.

  Assertions:
    (a) Jido.list_agents contains the new agent id.
    (b) agent_instances row exists with status "running".
    (c) audit_events has a roster.hire row for the workspace.
    (d) LV re-renders with the new agent row visible.
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias JidoBuilderCore.Agents
  alias JidoBuilderCore.Agents.AgentInstance
  alias JidoBuilderCore.Audit.AuditEvent
  alias JidoBuilderCore.Repo

  setup %{conn: conn} do
    {:ok, workspace} =
      Agents.create_workspace(
        %{
          name: "roster-test-ws-#{System.unique_integer()}",
          slug: "roster-ws-#{System.unique_integer()}"
        },
        "test-setup"
      )

    {:ok, lv, _html} = live(conn, ~p"/roster?workspace_id=#{workspace.id}")

    on_exit(fn ->
      # best-effort cleanup of any agents started during the test
      :ok
    end)

    %{workspace: workspace, lv: lv}
  end

  test "hire form starts agent, creates DB row, logs audit, updates stream",
       %{lv: lv, workspace: ws} do
    agent_name = "hire-test-agent-#{System.unique_integer([:positive])}"

    # (d) submit the hire form and check the rendered HTML
    html =
      lv
      |> form("#hire-form", hire: %{display_name: agent_name})
      |> render_submit()

    assert html =~ agent_name

    # (a) agent appears in the live Jido registry
    agents = Jido.list_agents(JidoBuilderRuntime.Jido)
    assert Enum.any?(agents, fn {id, _pid} -> id == agent_name end)

    # (b) agent_instances row with status "running"
    assert Repo.one(
             from a in AgentInstance,
               where:
                 a.name == ^agent_name and a.status == "running" and
                   a.workspace_id == ^ws.id
           )

    # (c) roster.hire audit event for this workspace
    assert Repo.one(
             from e in AuditEvent,
               where: e.workspace_id == ^ws.id and e.action == "roster.hire"
           )
  end
end
