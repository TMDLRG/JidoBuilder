defmodule JidoBuilderWeb.Live.AgentDetailTest do
  @moduledoc """
  Phase 2.5 — Agent detail page shows agent state + recent events.
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.Agents
  alias JidoBuilderRuntime.Roster

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "detail-ws-#{System.unique_integer()}", slug: "detail-ws-#{System.unique_integer()}"},
        "test"
      )

    name = "detail-agent-#{System.unique_integer([:positive])}"
    {:ok, _instance} = Roster.hire(workspace.id, name, "test")
    %{workspace: workspace, agent_name: name}
  end

  test "agent detail page renders agent name and state section",
       %{conn: conn, agent_name: name} do
    {:ok, _lv, html} = live(conn, ~p"/agents/#{name}")

    assert html =~ name
    assert html =~ "Agent State"
    assert html =~ "Agent Event Stream"
  end

  test "agent detail shows status for DB-persisted instance",
       %{conn: conn, agent_name: name} do
    {:ok, _lv, html} = live(conn, ~p"/agents/#{name}")

    assert html =~ "running" or html =~ "unknown"
  end
end
