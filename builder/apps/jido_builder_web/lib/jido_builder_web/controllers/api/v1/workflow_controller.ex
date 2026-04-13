defmodule JidoBuilderWeb.Api.V1.WorkflowController do
  @moduledoc "Story 4.3 — REST API for workflow CRUD and execution."
  use JidoBuilderWeb, :controller

  alias JidoBuilderCore.Workflows

  def index(conn, params) do
    workspace_id = conn.assigns.workspace_id
    {limit, offset} = parse_pagination(params)
    all = Workflows.list_workflows(workspace_id)
    page = all |> Enum.drop(offset) |> Enum.take(limit)

    json(conn, %{
      data: Enum.map(page, &serialize/1),
      meta: %{total: length(all), limit: limit, offset: offset}
    })
  end

  def show(conn, %{"id" => id}) do
    case Workflows.get_workflow(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Workflow not found"})
      workflow -> json(conn, %{data: serialize(workflow)})
    end
  end

  def create(conn, params) do
    workspace_id = conn.assigns.workspace_id
    actor = "api:#{conn.assigns.api_key.id}"

    attrs =
      params
      |> Map.take(["name", "description", "metadata"])
      |> Map.put("workspace_id", workspace_id)

    case Workflows.create_workflow(attrs, actor) do
      {:ok, workflow} ->
        conn |> put_status(201) |> json(%{data: serialize(workflow)})

      {:error, changeset} ->
        conn |> put_status(422) |> json(%{error: format_errors(changeset)})
    end
  end

  defp serialize(w) do
    %{
      id: w.id,
      name: w.name,
      description: w.description,
      inserted_at: w.inserted_at
    }
  end

  defp parse_pagination(params) do
    limit =
      case params["limit"] do
        nil -> 50
        val when is_binary(val) -> val |> String.to_integer() |> max(1) |> min(100)
        val when is_integer(val) -> val |> max(1) |> min(100)
        _ -> 50
      end

    offset =
      case params["offset"] do
        nil -> 0
        val when is_binary(val) -> val |> String.to_integer() |> max(0)
        val when is_integer(val) -> max(val, 0)
        _ -> 0
      end

    {limit, offset}
  end

  defp format_errors(%Ecto.Changeset{} = cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, _opts} -> msg end)
  end

  defp format_errors(other), do: inspect(other)
end
