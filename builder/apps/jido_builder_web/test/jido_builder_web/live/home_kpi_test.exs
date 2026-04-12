defmodule JidoBuilderWeb.Live.HomeKpiTest do
  @moduledoc """
  Phase 2.2 — Home KPIs: running agent count + workspace stats.
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.Agents
  alias JidoBuilderRuntime.Roster

  test "dashboard shows agent count KPI", %{conn: conn} do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "kpi-ws-#{System.unique_integer()}", slug: "kpi-ws-#{System.unique_integer()}"},
        "test"
      )

    {:ok, _} = Roster.hire(workspace.id, "kpi-agent-1", "test")
    {:ok, _} = Roster.hire(workspace.id, "kpi-agent-2", "test")

    {:ok, _lv, html} = live(conn, ~p"/?workspace_id=#{workspace.id}")

    assert html =~ "Running Agents"
    assert html =~ "2"
  end

  test "dashboard shows zero agents when none hired", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/?workspace_id=999999")

    assert html =~ "Running Agents"
    assert html =~ "0"
  end
end
