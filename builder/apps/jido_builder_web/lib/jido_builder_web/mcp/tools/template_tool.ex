defmodule JidoBuilderWeb.MCP.Tools.TemplateTool do
  @moduledoc "MCP tool: jido_template — manage agent templates."

  alias JidoBuilderCore.Templates

  def call(%{"action" => "list"}, %{workspace_id: ws_id}) do
    templates = Templates.list_templates(ws_id)
    {:ok, Enum.map(templates, fn t -> %{id: t.id, name: t.name, slug: t.slug, status: t.status} end)}
  end

  def call(%{"action" => "get", "id" => id}, _ctx) do
    case JidoBuilderCore.Repo.get(JidoBuilderCore.Templates.Template, id) do
      nil -> {:error, "Template not found"}
      t -> {:ok, %{id: t.id, name: t.name, slug: t.slug, version: t.version, status: t.status}}
    end
  end

  def call(%{"action" => "list_routes", "id" => id}, _ctx) when is_integer(id) do
    routes = Templates.list_routes(id)
    {:ok, Enum.map(routes, fn r -> %{signal: r.signal, target: r.target, action: r.action} end)}
  end

  def call(%{"action" => "create"} = args, %{workspace_id: ws_id}) do
    attrs = %{
      "workspace_id" => ws_id,
      "name" => args["name"],
      "slug" => args["slug"],
      "version" => args["version"] || "1.0.0",
      "status" => args["status"] || "active"
    }
    case Templates.create_template(attrs, "mcp") do
      {:ok, t} -> {:ok, %{id: t.id, name: t.name, slug: t.slug}}
      {:error, cs} -> {:error, inspect(cs.errors)}
    end
  end

  def call(%{"action" => "delete", "id" => id}, _ctx) do
    case JidoBuilderCore.Repo.get(JidoBuilderCore.Templates.Template, id) do
      nil -> {:error, "Template not found"}
      t -> case Templates.delete_template(t, "mcp") do
        {:ok, _} -> {:ok, %{deleted: true}}
        {:error, err} -> {:error, inspect(err)}
      end
    end
  end

  def call(_, _), do: {:ok, "jido_template — Actions: list, get, create, delete, list_routes, help"}
end
