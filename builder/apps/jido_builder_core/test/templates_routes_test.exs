defmodule JidoBuilderCore.TemplatesRoutesTest do
  @moduledoc "Story 10.1 — Template routes coverage."
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, Templates, Repo}

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "routes-#{System.unique_integer()}", slug: "routes-#{System.unique_integer()}"},
        "test"
      )

    {:ok, template} =
      Templates.create_template(
        %{"name" => "Route Test", "slug" => "route-test", "workspace_id" => workspace.id, "status" => "active", "version" => "1.0.0"},
        "test"
      )

    %{workspace: workspace, template: template}
  end

  test "create_route adds a route to template", %{template: tmpl} do
    {:ok, route} = Templates.create_route(%{"template_id" => tmpl.id, "signal" => "ping", "action" => "echo", "target" => "self"}, "test")
    assert route.signal == "ping"
    assert route.action == "echo"
  end

  test "list_routes returns routes for template", %{template: tmpl} do
    {:ok, _} = Templates.create_route(%{"template_id" => tmpl.id, "signal" => "ping", "action" => "echo", "target" => "self"}, "test")
    {:ok, _} = Templates.create_route(%{"template_id" => tmpl.id, "signal" => "pong", "action" => "log_message", "target" => "self"}, "test")

    routes = Templates.list_routes(tmpl.id)
    assert length(routes) == 2
  end

  test "list_templates returns templates for workspace", %{workspace: ws} do
    templates = Templates.list_templates(ws.id)
    assert length(templates) >= 1
  end

  test "get_template! returns template by id", %{template: tmpl} do
    found = Templates.get_template!(tmpl.id)
    assert found.id == tmpl.id
    assert found.name == "Route Test"
  end
end
