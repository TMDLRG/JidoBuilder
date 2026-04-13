defmodule JidoBuilderWeb.Api.V1.TemplateController do
  @moduledoc "Story 4.3 — REST API for template CRUD."
  use JidoBuilderWeb, :controller

  alias JidoBuilderCore.Templates

  def index(conn, params) do
    workspace_id = conn.assigns.workspace_id
    {limit, offset} = parse_pagination(params)
    all = Templates.list_templates(workspace_id)
    page = all |> Enum.drop(offset) |> Enum.take(limit)

    json(conn, %{
      data: Enum.map(page, &serialize/1),
      meta: %{total: length(all), limit: limit, offset: offset}
    })
  end

  def show(conn, %{"id" => id}) do
    try do
      template = Templates.get_template!(id)
      json(conn, %{data: serialize(template)})
    rescue
      Ecto.NoResultsError ->
        conn |> put_status(404) |> json(%{error: "Template not found"})
    end
  end

  def create(conn, params) do
    workspace_id = conn.assigns.workspace_id
    actor = "api:#{conn.assigns.api_key.id}"

    attrs =
      params
      |> Map.take(["name", "slug", "description", "version", "status", "config"])
      |> Map.put("workspace_id", workspace_id)

    case Templates.create_template(attrs, actor) do
      {:ok, template} ->
        conn |> put_status(201) |> json(%{data: serialize(template)})

      {:error, changeset} ->
        conn |> put_status(422) |> json(%{error: format_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    actor = "api:#{conn.assigns.api_key.id}"

    try do
      template = Templates.get_template!(id)

      case Templates.delete_template(template, actor) do
        {:ok, _} -> json(conn, %{data: %{deleted: true}})
        {:error, reason} -> conn |> put_status(422) |> json(%{error: inspect(reason)})
      end
    rescue
      Ecto.NoResultsError ->
        conn |> put_status(404) |> json(%{error: "Template not found"})
    end
  end

  defp serialize(t) do
    %{
      id: t.id,
      name: t.name,
      slug: t.slug,
      description: t.description,
      version: t.version,
      status: t.status,
      inserted_at: t.inserted_at
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
