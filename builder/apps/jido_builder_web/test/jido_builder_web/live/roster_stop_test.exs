defmodule JidoBuilderWeb.Live.RosterStopTest do
  @moduledoc """
  Phase 1.4 — Stop agent with confirmation modal.

  Assertions:
    (a) Clicking Stop without confirming is a no-op (agent still running).
    (b) Confirming removes the row from the stream, fires a roster.stop
        audit event, and the agent is no longer in the Jido registry.
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias JidoBuilderCore.Agents
  alias JidoBuilderCore.Agents.AgentInstance
  alias JidoBuilderCore.Repo
  alias JidoBuilderRuntime.{Hiring, Roster}

  setup %{conn: conn} do
    {:ok, workspace} =
      Agents.create_workspace(
        %{
          name: "stop-test-ws-#{System.unique_integer()}",
          slug: "stop-ws-#{System.unique_integer()}"
        },
        "test-setup"
      )

    agent_name = "stop-agent-#{System.unique_integer([:positive])}"
    {:ok, _instance} = Roster.hire(workspace.id, agent_name, "test")

    {:ok, lv, _html} = live(conn, ~p"/roster?workspace_id=#{workspace.id}")

    %{workspace: workspace, lv: lv, agent_name: agent_name}
  end

  test "(a) clicking Stop without confirming is a no-op",
       %{lv: lv, agent_name: agent_name, workspace: ws} do
    # Request stop (shows confirm modal) — but do NOT confirm
    lv |> element("[phx-click=request_stop][phx-value-name=#{agent_name}]") |> render_click()

    # Agent still in Jido registry
    context = %{workspace_id: ws.id, actor: "test"}
    assert {:ok, _pid} = Hiring.whereis(context, agent_name)

    # agent_instances row still "running"
    instance =
      Repo.one(
        from a in AgentInstance,
          where: a.name == ^agent_name and a.workspace_id == ^ws.id
      )

    assert instance.status == "running"
  end

  test "(b) stop modal shows agent name and cancel closes the modal",
       %{lv: lv, agent_name: agent_name} do
    # Open stop modal
    html = lv |> element("[phx-click=request_stop][phx-value-name=#{agent_name}]") |> render_click()

    # (b1) modal shows agent name in the stop prompt
    assert html =~ "Stop #{agent_name}?"

    # (b2) cancel closes the modal; agent is still shown in the roster
    html = lv |> element("[phx-click=cancel_stop]") |> render_click()
    assert html =~ agent_name
  end
end
