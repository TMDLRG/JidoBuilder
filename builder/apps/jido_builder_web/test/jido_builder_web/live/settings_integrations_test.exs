defmodule JidoBuilderWeb.Live.SettingsIntegrationsTest do
  @moduledoc "Phase 4 — Settings/Integrations/Secrets: extended settings page."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated
  import Phoenix.LiveViewTest
  alias JidoBuilderCore.{Agents, Security}

  setup do
    {:ok, ws} =
      Agents.create_workspace(
        %{name: "settings-ws-#{System.unique_integer()}", slug: "settings-#{System.unique_integer()}"},
        "test"
      )
    {:ok, integ} =
      Security.create_integration(
        %{workspace_id: ws.id, name: "GitHub", provider: "github", status: "active", config: %{token: "abc"}},
        "test"
      )
    %{workspace: ws, integration: integ}
  end

  test "renders Settings with integrations section", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/settings")
    assert html =~ "Settings"
    assert html =~ "Integrations"
  end

  test "lists integrations for workspace (redacted)", %{conn: conn, workspace: ws} do
    {:ok, _lv, html} = live(conn, ~p"/settings?workspace_id=#{ws.id}")
    assert html =~ "GitHub"
  end

  test "create secret form works", %{conn: conn, workspace: ws} do
    {:ok, lv, _html} = live(conn, ~p"/settings?workspace_id=#{ws.id}")

    html =
      lv
      |> form("#secret-form",
        secret: %{name: "API_KEY", value: "sk-12345"}
      )
      |> render_submit()

    assert html =~ "API_KEY"
  end
end
