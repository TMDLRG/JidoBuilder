defmodule JidoBuilderRuntime.ExporterTest do
  @moduledoc "Epic 9 — Code export tests."
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, Templates, Workflows}
  alias JidoBuilderRuntime.Exporter

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(JidoBuilderCore.Repo)
    :ok = Ecto.Adapters.SQL.Sandbox.mode(JidoBuilderCore.Repo, {:shared, self()})

    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "export-ws-#{System.unique_integer()}", slug: "export-ws-#{System.unique_integer()}"},
        "test"
      )

    {:ok, template} =
      Templates.create_template(
        %{workspace_id: workspace.id, name: "Export Template", slug: "export-tmpl", version: "1.0.0", status: "active", description: "An exportable template"},
        "test"
      )

    Templates.create_route(%{template_id: template.id, signal: "ping", target: "self", action: "echo"}, "test")

    {:ok, workflow} =
      Workflows.create_workflow(%{workspace_id: workspace.id, name: "ExportFlow", description: "test workflow", status: "draft"}, "test")

    [workspace: workspace, template: template, workflow: workflow]
  end

  test "export_agent generates valid Elixir module code", %{template: t} do
    {:ok, code} = Exporter.export_agent(t.id)
    assert code =~ "defmodule MyApp.Agents"
    assert code =~ "use Jido.Agent"
    assert code =~ "ping"
    assert code =~ "Echo"
  end

  test "export_agent returns error for missing template" do
    assert {:error, :template_not_found} = Exporter.export_agent(999_999)
  end

  test "export_workflow generates valid Elixir module code", %{workflow: w} do
    {:ok, code} = Exporter.export_workflow(w.id)
    assert code =~ "defmodule MyApp.Workflows"
    assert code =~ "def execute"
    assert code =~ "def steps"
  end

  test "export_project generates file tree", %{workspace: ws} do
    {:ok, files} = Exporter.export_project(ws.id)
    assert Map.has_key?(files, "mix.exs")
    assert Map.has_key?(files, "config/config.exs")
    assert Map.has_key?(files, "lib/application.ex")
    # Should have at least the agent file
    agent_files = Enum.filter(Map.keys(files), fn k -> String.starts_with?(k, "lib/agents/") end)
    assert length(agent_files) >= 1
  end
end
