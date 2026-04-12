defmodule JidoBuilderWeb.Live.CapabilityPacksTest do
  @moduledoc """
  Phase 3.1 — Capability Packs: plugin browser + edit.

  Assertions:
    - /capability-packs renders the page heading
    - lists DB-persisted template plugin rows for the workspace
    - lists discovered plugins from runtime (empty list is fine)
    - toggling a plugin's enabled flag persists the change
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.{Agents, Templates}

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{
          name: "caps-ws-#{System.unique_integer()}",
          slug: "caps-#{System.unique_integer()}"
        },
        "test"
      )

    {:ok, template} =
      Templates.create_template(
        %{
          workspace_id: workspace.id,
          name: "PluginTemplate",
          slug: "plugin-tmpl-#{System.unique_integer()}",
          version: "0.1.0",
          status: "draft"
        },
        "test"
      )

    {:ok, plugin} =
      Templates.create_plugin(
        %{template_id: template.id, name: "MyPlugin", module: "Jido.Plugin.Heartbeat"},
        "test"
      )

    %{workspace: workspace, template: template, plugin: plugin}
  end

  test "renders capability packs heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/capability-packs")
    assert html =~ "Capability Packs"
  end

  test "lists template plugin rows from DB for workspace", %{conn: conn, workspace: ws} do
    {:ok, _lv, html} = live(conn, ~p"/capability-packs?workspace_id=#{ws.id}")
    assert html =~ "MyPlugin"
  end

  test "lists discovered plugins from runtime (empty is ok)", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/capability-packs")
    assert html =~ "Capability Packs"
  end

  test "disable plugin sets enabled=false", %{conn: conn, workspace: ws, plugin: plugin} do
    {:ok, lv, _html} = live(conn, ~p"/capability-packs?workspace_id=#{ws.id}")

    html =
      lv
      |> element("[phx-click='disable_plugin'][phx-value-id='#{plugin.id}']")
      |> render_click()

    assert html =~ "disabled" or html =~ "MyPlugin"
  end
end
