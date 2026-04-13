defmodule JidoBuilderWeb.Live.RosterTemplateHireTest do
  @moduledoc """
  Story 3.1 — RosterLive "Hire from Template" flow.

  Assertions:
    (a) Hire modal shows template dropdown populated from workspace templates
    (b) Hiring with a selected template creates agent with template_id set
    (c) Roster card shows template name instead of "bare" when template-backed
    (d) Hiring without template selection still works (bare agent)
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias JidoBuilderCore.{Agents, Templates, Repo}
  alias JidoBuilderCore.Agents.AgentInstance

  setup %{conn: conn} do
    {:ok, workspace} =
      Agents.create_workspace(
        %{
          name: "tmpl-hire-ui-#{System.unique_integer()}",
          slug: "tmpl-ui-#{System.unique_integer()}"
        },
        "test-setup"
      )

    {:ok, template} =
      Templates.create_template(
        %{
          workspace_id: workspace.id,
          name: "UI Test Template",
          slug: "ui-test-tmpl-#{System.unique_integer()}",
          version: "1.0.0",
          status: "active"
        },
        "test-setup"
      )

    {:ok, _route} =
      Templates.create_route(
        %{template_id: template.id, signal: "ping", target: "self", action: "echo"},
        "test-setup"
      )

    {:ok, lv, _html} = live(conn, ~p"/roster?workspace_id=#{workspace.id}")

    %{workspace: workspace, template: template, lv: lv}
  end

  test "hire modal shows template dropdown", %{lv: lv, template: template} do
    html = lv |> element("button", "Hire") |> render_click()

    # Template dropdown should exist with "Bare Agent" default and our template
    assert html =~ "Template"
    assert html =~ "Bare Agent"
    assert html =~ template.name
  end

  test "hiring with template creates agent with template_id", %{
    lv: lv,
    workspace: ws,
    template: template
  } do
    # Open hire modal
    lv |> element("button", "Hire") |> render_click()

    agent_name = "tmpl-ui-agent-#{System.unique_integer([:positive])}"

    # Submit hire form with template selected
    lv
    |> form("#hire-form", %{
      "hire" => %{"name" => agent_name, "template_id" => to_string(template.id)}
    })
    |> render_submit()

    # Agent instance should have template_id
    instance = Repo.one(from a in AgentInstance, where: a.name == ^agent_name)
    assert instance
    assert instance.template_id == template.id
    assert instance.workspace_id == ws.id
  end

  test "roster card shows template name for template-backed agent", %{
    lv: lv,
    template: template
  } do
    lv |> element("button", "Hire") |> render_click()

    agent_name = "tmpl-display-#{System.unique_integer([:positive])}"

    lv
    |> form("#hire-form", %{
      "hire" => %{"name" => agent_name, "template_id" => to_string(template.id)}
    })
    |> render_submit()

    html = render(lv)
    assert html =~ agent_name
    assert html =~ template.name
  end

  test "hiring without template still creates bare agent", %{lv: lv, workspace: ws} do
    lv |> element("button", "Hire") |> render_click()

    agent_name = "bare-ui-#{System.unique_integer([:positive])}"

    lv
    |> form("#hire-form", %{"hire" => %{"name" => agent_name, "template_id" => ""}})
    |> render_submit()

    instance = Repo.one(from a in AgentInstance, where: a.name == ^agent_name)
    assert instance
    assert is_nil(instance.template_id)
    assert instance.workspace_id == ws.id
  end
end
