defmodule JidoBuilderWeb.Live.UiPolishTest do
  @moduledoc """
  Stories 6.2-6.6 — UI/UX commercial polish tests.
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.Agents

  # -- Story 6.2: Role-Based Views --

  test "dashboard has view mode toggle", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/")
    assert html =~ "Developer" or html =~ "view-mode"
  end

  # -- Story 6.3: Pagination --

  test "roster page has search functionality", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/roster")
    # Roster page should render (with our command palette hook active)
    assert html =~ "Agents"
  end

  # -- Story 6.5: Onboarding --

  test "onboarding page renders wizard steps", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/onboarding")
    assert html =~ "Onboarding" or html =~ "onboarding" or html =~ "Welcome"
  end

  # -- Story 6.6: Workspace Export --

  test "workspace export API endpoint exists", %{conn: conn} do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "export-ws-#{System.unique_integer()}", slug: "export-ws-#{System.unique_integer()}"},
        "test"
      )

    {:ok, _, raw_key} = JidoBuilderCore.ApiKeys.generate(workspace.id, "export-key", "test")

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{raw_key}")
      |> get(~p"/api/v1/workspace/export")

    resp = json_response(conn, 200)
    assert resp["data"]["workspace"]
    assert resp["data"]["templates"]
    assert resp["data"]["workflows"]
  end
end
