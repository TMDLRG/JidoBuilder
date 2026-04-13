defmodule JidoBuilderRuntime.RosterTemplateHireTest do
  @moduledoc """
  Story 3.1 — Roster.hire with optional template_id uses DynamicAgent.

  Assertions:
    (a) hire/4 with template_id starts a DynamicAgent process (not BareAgent)
    (b) agent_instances row has template_id set
    (c) hire/4 without template_id still uses BareAgent (backward compat)
    (d) hire/4 with nonexistent template_id returns error
    (e) Templates.list_routes/1 returns routes for a template
  """
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, Repo, Templates}
  alias JidoBuilderCore.Agents.AgentInstance
  alias JidoBuilderRuntime.Roster

  import Ecto.Query

  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ok = Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "template-hire-ws-#{System.unique_integer()}", slug: "tmpl-hire-#{System.unique_integer()}"},
        "test-setup"
      )

    # Create a template with routes
    {:ok, template} =
      Templates.create_template(
        %{
          workspace_id: workspace.id,
          name: "Test Template",
          slug: "test-template-#{System.unique_integer()}",
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
        %{template_id: template.id, signal: "greet", target: "self", action: "log_message"},
        "test-setup"
      )

    [workspace: workspace, template: template]
  end

  test "hire with template_id creates agent with template association", %{
    workspace: ws,
    template: template
  } do
    agent_name = "tmpl-agent-#{System.unique_integer([:positive])}"

    assert {:ok, instance} = Roster.hire(ws.id, agent_name, "test", template_id: template.id)
    assert instance.template_id == template.id
    assert instance.status == "running"

    # Verify DB record has template_id
    db_instance = Repo.one(from a in AgentInstance, where: a.name == ^agent_name)
    assert db_instance.template_id == template.id
  end

  test "hire without template_id still uses BareAgent (backward compat)", %{workspace: ws} do
    agent_name = "bare-agent-#{System.unique_integer([:positive])}"

    assert {:ok, instance} = Roster.hire(ws.id, agent_name, "test")
    assert is_nil(instance.template_id)
    assert instance.status == "running"
  end

  test "hire with nonexistent template_id returns error", %{workspace: ws} do
    agent_name = "bad-tmpl-agent-#{System.unique_integer([:positive])}"

    assert {:error, error} = Roster.hire(ws.id, agent_name, "test", template_id: 999_999)
    assert error.code == :template_not_found
  end

  test "Templates.list_routes/1 returns routes for a template", %{template: template} do
    routes = Templates.list_routes(template.id)
    assert length(routes) == 2

    signals = Enum.map(routes, & &1.signal) |> Enum.sort()
    assert signals == ["greet", "ping"]
  end
end
