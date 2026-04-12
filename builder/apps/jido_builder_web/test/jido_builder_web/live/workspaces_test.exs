defmodule JidoBuilderWeb.Live.WorkspacesTest do
  @moduledoc "Phase 4 — Workspaces: partition CRUD."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated
  import Phoenix.LiveViewTest
  import Ecto.Query
  alias JidoBuilderCore.{Agents, Repo}
  alias JidoBuilderCore.Agents.Workspace

  test "renders Workspaces heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/workspaces")
    assert html =~ "Workspaces"
  end

  test "create workspace form inserts row", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/workspaces")

    html =
      lv
      |> form("#workspace-form",
        workspace: %{name: "NewSpace", slug: "new-space-#{System.unique_integer()}"}
      )
      |> render_submit()

    assert html =~ "NewSpace"
  end

  test "lists existing workspaces", %{conn: conn} do
    {:ok, _ws} =
      Agents.create_workspace(
        %{name: "ListMe", slug: "list-me-#{System.unique_integer()}"},
        "test"
      )
    {:ok, _lv, html} = live(conn, ~p"/workspaces")
    assert html =~ "ListMe"
  end

  test "create partition form inserts row", %{conn: conn} do
    {:ok, ws} =
      Agents.create_workspace(
        %{name: "PartWs", slug: "part-ws-#{System.unique_integer()}"},
        "test"
      )
    {:ok, lv, _html} = live(conn, ~p"/workspaces")

    html =
      lv
      |> form("#partition-form",
        partition: %{workspace_id: ws.id, name: "Shard-1", key: "shard-1-#{System.unique_integer()}"}
      )
      |> render_submit()

    assert html =~ "Shard-1"
  end
end
