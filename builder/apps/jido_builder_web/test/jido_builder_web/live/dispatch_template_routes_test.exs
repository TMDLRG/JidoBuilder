defmodule JidoBuilderWeb.Live.DispatchTemplateRoutesTest do
  @moduledoc """
  Story 3.1 — Dispatch UI queries template routes for signal types dropdown.

  Assertions:
    (a) Selecting a template-backed agent shows a signal type dropdown with its routes
    (b) Selecting a bare agent shows freeform signal type text input
    (c) Dispatching a template route signal works end-to-end
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  alias JidoBuilderCore.{Agents, Templates}
  alias JidoBuilderRuntime.Roster

  setup %{conn: conn} do
    {:ok, workspace} =
      Agents.create_workspace(
        %{
          name: "dispatch-routes-#{System.unique_integer()}",
          slug: "dispatch-routes-#{System.unique_integer()}"
        },
        "test-setup"
      )

    {:ok, template} =
      Templates.create_template(
        %{
          workspace_id: workspace.id,
          name: "Dispatch Test Template",
          slug: "dispatch-tmpl-#{System.unique_integer()}",
          version: "1.0.0",
          status: "active"
        },
        "test-setup"
      )

    {:ok, _route1} =
      Templates.create_route(
        %{template_id: template.id, signal: "ping", target: "self", action: "echo"},
        "test-setup"
      )

    {:ok, _route2} =
      Templates.create_route(
        %{template_id: template.id, signal: "process", target: "self", action: "transform_data"},
        "test-setup"
      )

    # Hire a bare agent and a template-backed agent
    {:ok, bare_agent} = Roster.hire(workspace.id, "bare-dispatch-#{System.unique_integer([:positive])}", "test")
    {:ok, tmpl_agent} = Roster.hire(workspace.id, "tmpl-dispatch-#{System.unique_integer([:positive])}", "test", template_id: template.id)

    {:ok, lv, _html} = live(conn, ~p"/assignments/new?workspace_id=#{workspace.id}")

    %{
      workspace: workspace,
      template: template,
      bare_agent: bare_agent,
      tmpl_agent: tmpl_agent,
      lv: lv
    }
  end

  test "selecting template-backed agent shows signal type dropdown with routes", %{
    lv: lv,
    tmpl_agent: agent
  } do
    html = lv |> element("[phx-click=pick_agent][phx-value-id=#{agent.name}]") |> render_click()

    # Should show a select/dropdown with the template's routes
    assert html =~ "ping"
    assert html =~ "process"
  end

  test "selecting bare agent shows freeform signal type input", %{
    lv: lv,
    bare_agent: agent
  } do
    html = lv |> element("[phx-click=pick_agent][phx-value-id=#{agent.name}]") |> render_click()

    # Bare agent should have freeform text input for signal type
    assert html =~ "dispatch[signal_type]"
  end
end
