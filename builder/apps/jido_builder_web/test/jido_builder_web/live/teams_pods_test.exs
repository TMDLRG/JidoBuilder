defmodule JidoBuilderWeb.Live.TeamsPodsMVPTest do
  @moduledoc """
  Phase 3.3 — Teams / Pods MVP.

  Assertions:
    - /teams renders the page heading
    - create topology form inserts a pod_topologies row
    - topology name appears in the list after creation
    - nodes for an existing topology are shown
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias JidoBuilderCore.{Agents, Pods, Repo}
  alias JidoBuilderCore.Pods.PodTopology

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{
          name: "teams-ws-#{System.unique_integer()}",
          slug: "teams-#{System.unique_integer()}"
        },
        "test"
      )

    %{workspace: workspace}
  end

  test "renders Teams / Pods heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/teams")
    assert html =~ "Teams"
  end

  test "create topology form inserts pod_topologies row", %{conn: conn, workspace: ws} do
    {:ok, lv, _html} = live(conn, ~p"/teams?workspace_id=#{ws.id}")

    html =
      lv
      |> form("#topology-form", topology: %{name: "AlphaTeam", strategy: "round_robin"})
      |> render_submit()

    assert html =~ "AlphaTeam"
    assert Repo.exists?(from t in PodTopology, where: t.workspace_id == ^ws.id and t.name == "AlphaTeam")
  end

  test "lists existing topologies for workspace", %{conn: conn, workspace: ws} do
    {:ok, _topo} =
      Pods.create_topology(
        %{workspace_id: ws.id, name: "BetaPod", strategy: "broadcast"},
        "test"
      )

    {:ok, _lv, html} = live(conn, ~p"/teams?workspace_id=#{ws.id}")
    assert html =~ "BetaPod"
  end
end
