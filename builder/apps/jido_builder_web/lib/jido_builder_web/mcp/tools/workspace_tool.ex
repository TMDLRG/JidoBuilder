defmodule JidoBuilderWeb.MCP.Tools.WorkspaceTool do
  @moduledoc "MCP tool: jido_workspace — manage workspaces."

  alias JidoBuilderCore.Agents

  def call(%{"action" => "list"}, _ctx) do
    workspaces = Agents.list_workspaces()
    {:ok, Enum.map(workspaces, fn w -> %{id: w.id, name: w.name, slug: w.slug} end)}
  end

  def call(%{"action" => "create"} = args, _ctx) do
    case Agents.create_workspace(%{name: args["name"], slug: args["slug"]}, "mcp") do
      {:ok, w} -> {:ok, %{id: w.id, name: w.name, slug: w.slug}}
      {:error, cs} -> {:error, inspect(cs.errors)}
    end
  end

  def call(_, _), do: {:ok, "jido_workspace — Actions: list, create, help"}
end
