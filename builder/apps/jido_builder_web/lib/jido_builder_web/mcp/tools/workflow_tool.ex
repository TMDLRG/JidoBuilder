defmodule JidoBuilderWeb.MCP.Tools.WorkflowTool do
  @moduledoc "MCP tool: jido_workflow — manage workflows."

  alias JidoBuilderCore.Workflows

  def call(%{"action" => "list"}, %{workspace_id: ws_id}) do
    workflows = Workflows.list_workflows(ws_id)
    {:ok, Enum.map(workflows, fn w -> %{id: w.id, name: w.name} end)}
  end

  def call(%{"action" => "get", "id" => id}, _ctx) do
    case Workflows.get_workflow(id) do
      nil -> {:error, "Workflow not found"}
      w -> {:ok, %{id: w.id, name: w.name, description: w.description}}
    end
  end

  def call(%{"action" => "create"} = args, %{workspace_id: ws_id}) do
    attrs = %{"workspace_id" => ws_id, "name" => args["name"], "description" => args["description"]}
    case Workflows.create_workflow(attrs, "mcp") do
      {:ok, w} -> {:ok, %{id: w.id, name: w.name}}
      {:error, cs} -> {:error, inspect(cs.errors)}
    end
  end

  def call(_, _), do: {:ok, "jido_workflow — Actions: list, get, create, run, help"}
end
