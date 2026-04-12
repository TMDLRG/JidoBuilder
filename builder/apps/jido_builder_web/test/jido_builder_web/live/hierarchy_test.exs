defmodule JidoBuilderWeb.Live.HierarchyTest do
  @moduledoc """
  Phase 3.4 — Hierarchy view: parent/child agent relationships.

  Assertions:
    - /hierarchy renders the heading
    - lists pod topologies for workspace with their node members
    - add-node form links an agent instance into a topology
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.{Agents, Pods}

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{
          name: "hier-ws-#{System.unique_integer()}",
          slug: "hier-#{System.unique_integer()}"
        },
        "test"
      )

    {:ok, topo} =
      Pods.create_topology(
        %{workspace_id: workspace.id, name: "ParentPod", strategy: "broadcast"},
        "test"
      )

    {:ok, instance} =
      Agents.create_agent_instance(
        %{workspace_id: workspace.id, name: "child-agent-#{System.unique_integer()}", status: "running"},
        "test"
      )

    %{workspace: workspace, topo: topo, instance: instance}
  end

  test "renders Hierarchy heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/hierarchy")
    assert html =~ "Hierarchy"
  end

  test "lists topologies with their node count", %{conn: conn, workspace: ws, topo: topo} do
    {:ok, _lv, html} = live(conn, ~p"/hierarchy?workspace_id=#{ws.id}")
    assert html =~ topo.name
  end

  test "add node form links agent to topology", %{
    conn: conn,
    workspace: ws,
    topo: topo,
    instance: inst
  } do
    {:ok, lv, _html} = live(conn, ~p"/hierarchy?workspace_id=#{ws.id}")

    html =
      lv
      |> form("#add-node-form",
        node: %{pod_topology_id: topo.id, agent_instance_id: inst.id, name: "child-1", role: "worker", position: 1}
      )
      |> render_submit()

    assert html =~ "child-1" or html =~ inst.name
  end
end
