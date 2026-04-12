defmodule JidoBuilderWeb.Live.VaultTest do
  @moduledoc "Phase 4 — Vault: hibernate/thaw agent snapshots."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated
  import Phoenix.LiveViewTest
  alias JidoBuilderCore.Agents

  setup do
    {:ok, ws} =
      Agents.create_workspace(
        %{name: "vault-ws-#{System.unique_integer()}", slug: "vault-#{System.unique_integer()}"},
        "test"
      )
    {:ok, inst} =
      Agents.create_agent_instance(
        %{workspace_id: ws.id, name: "snap-agent-#{System.unique_integer()}", status: "running"},
        "test"
      )
    {:ok, _snap} =
      Agents.create_snapshot(
        %{workspace_id: ws.id, agent_instance_id: inst.id, captured_at: DateTime.utc_now(),
          hibernate_metadata: %{reason: "pre-deploy"}, metadata: %{label: "pre-deploy"}},
        "test"
      )
    %{workspace: ws, instance: inst}
  end

  test "renders Vault heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/vault")
    assert html =~ "Vault"
  end

  test "lists snapshots for workspace", %{conn: conn, workspace: ws} do
    {:ok, _lv, html} = live(conn, ~p"/vault?workspace_id=#{ws.id}")
    assert html =~ "pre-deploy"
  end
end
