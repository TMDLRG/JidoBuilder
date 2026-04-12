defmodule JidoBuilderWeb.Live.AuditHistoryTest do
  @moduledoc "Phase 4 — Audit History: lists audit events for a workspace."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated
  import Phoenix.LiveViewTest
  alias JidoBuilderCore.{Agents, Audit}

  setup do
    {:ok, ws} =
      Agents.create_workspace(
        %{name: "audit-ws-#{System.unique_integer()}", slug: "audit-#{System.unique_integer()}"},
        "test"
      )
    Audit.log("tester", "test.action", ws, %{detail: "hello"})
    %{workspace: ws}
  end

  test "renders Audit History heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/audit")
    assert html =~ "Audit"
  end

  test "shows audit event for workspace", %{conn: conn, workspace: ws} do
    {:ok, _lv, html} = live(conn, ~p"/audit?workspace_id=#{ws.id}")
    assert html =~ "test.action"
  end
end
