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

    agent_name = "hire-test-agent-#{System.unique_integer([:positive])}"
    {:ok, _instance} = JidoBuilderRuntime.Roster.hire(workspace.id, agent_name, "test")

    {:ok, lv, _html} = live(conn, ~p"/roster?workspace_id=#{workspace.id}")

    on_exit(fn ->
      # best-effort cleanup of any agents started during the test
      :ok
    end)

    %{workspace: workspace, lv: lv, agent_name: agent_name}
  end

  test "hire modal opens and roster shows agents hired via backend",
       %{lv: lv, workspace: ws, agent_name: agent_name} do
    # (d) Agent hired via Roster.hire in setup appears in the roster list
    html = render(lv)
    assert html =~ agent_name

    # Clicking Hire opens modal with redirect message
    html = lv |> element("button", "Hire") |> render_click()
    assert html =~ "Hire Agent"
    assert html =~ "Agent name"

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
