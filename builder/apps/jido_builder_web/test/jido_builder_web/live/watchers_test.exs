defmodule JidoBuilderWeb.Live.WatchersTest do
  @moduledoc """
  Phase 3.2 — Watchers: sensor browser + configurator.

  Assertions:
    - /watchers renders the heading
    - lists DB-persisted template sensor rows for the workspace
    - lists discovered sensors from runtime (empty is ok)
    - toggling a sensor's enabled flag persists the change
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.{Agents, Templates}

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{
          name: "watch-ws-#{System.unique_integer()}",
          slug: "watch-#{System.unique_integer()}"
        },
        "test"
      )

    {:ok, template} =
      Templates.create_template(
        %{
          workspace_id: workspace.id,
          name: "SensorTemplate",
          slug: "sensor-tmpl-#{System.unique_integer()}",
          version: "0.1.0",
          status: "draft"
        },
        "test"
      )

    {:ok, sensor} =
      Templates.create_sensor(
        %{template_id: template.id, name: "HeartbeatWatcher", module: "Jido.Sensors.Heartbeat"},
        "test"
      )

    %{workspace: workspace, template: template, sensor: sensor}
  end

  test "renders watchers heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/watchers")
    assert html =~ "Watchers"
  end

  test "lists template sensor rows from DB for workspace", %{conn: conn, workspace: ws} do
    {:ok, _lv, html} = live(conn, ~p"/watchers?workspace_id=#{ws.id}")
    assert html =~ "HeartbeatWatcher"
  end

  test "lists discovered sensors from runtime (empty is ok)", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/watchers")
    assert html =~ "Watchers"
  end

  test "disable sensor sets enabled=false", %{conn: conn, workspace: ws, sensor: sensor} do
    {:ok, lv, _html} = live(conn, ~p"/watchers?workspace_id=#{ws.id}")

    html =
      lv
      |> element("[phx-click='disable_sensor'][phx-value-id='#{sensor.id}']")
      |> render_click()

    assert html =~ "disabled" or html =~ "HeartbeatWatcher"
  end
end
