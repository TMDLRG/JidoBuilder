defmodule JidoBuilderWeb.Api.V1.WorkspaceController do
  @moduledoc "Story 6.6 — Workspace export/import API."
  use JidoBuilderWeb, :controller

  alias JidoBuilderCore.{Templates, Workflows}

  def export(conn, _params) do
    workspace_id = conn.assigns.workspace_id

    workspace = JidoBuilderCore.Repo.get(JidoBuilderCore.Agents.Workspace, workspace_id)
    templates = Templates.list_templates(workspace_id)
    workflows = Workflows.list_workflows(workspace_id)

    json(conn, %{
      data: %{
        workspace: %{id: workspace.id, name: workspace.name, slug: workspace.slug},
        templates: Enum.map(templates, fn t -> %{name: t.name, slug: t.slug, version: t.version, status: t.status} end),
        workflows: Enum.map(workflows, fn w -> %{name: w.name, description: w.description} end),
        exported_at: DateTime.utc_now()
      }
    })
  end
end
