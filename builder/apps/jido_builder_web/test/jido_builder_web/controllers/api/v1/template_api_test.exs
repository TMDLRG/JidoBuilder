defmodule JidoBuilderWeb.Api.V1.TemplateApiTest do
  @moduledoc "Story 4.3 — Template API tests."
  use JidoBuilderWeb.ConnCase, async: false

  alias JidoBuilderCore.{Agents, ApiKeys, Templates}

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "tmpl-api-#{System.unique_integer()}", slug: "tmpl-api-#{System.unique_integer()}"},
        "test"
      )

    {:ok, _api_key, raw_key} = ApiKeys.generate(workspace.id, "test-key", "test")

    {:ok, template} =
      Templates.create_template(
        %{workspace_id: workspace.id, name: "API Template", slug: "api-tmpl-#{System.unique_integer()}", version: "1.0.0", status: "active"},
        "test"
      )

    %{workspace: workspace, raw_key: raw_key, template: template}
  end

  defp api(conn, key), do: conn |> put_req_header("authorization", "Bearer #{key}") |> put_req_header("content-type", "application/json")

  test "GET /api/v1/templates lists templates", %{conn: conn, raw_key: key, template: t} do
    conn = conn |> api(key) |> get(~p"/api/v1/templates")
    assert %{"data" => templates} = json_response(conn, 200)
    assert Enum.any?(templates, fn tmpl -> tmpl["name"] == t.name end)
  end

  test "POST /api/v1/templates creates template", %{conn: conn, raw_key: key} do
    conn =
      conn
      |> api(key)
      |> post(~p"/api/v1/templates", %{name: "New Tmpl", slug: "new-tmpl-#{System.unique_integer()}", version: "1.0.0", status: "active"})

    assert %{"data" => %{"name" => "New Tmpl"}} = json_response(conn, 201)
  end

  test "GET /api/v1/templates/:id shows template", %{conn: conn, raw_key: key, template: t} do
    conn = conn |> api(key) |> get(~p"/api/v1/templates/#{t.id}")
    assert %{"data" => %{"name" => name}} = json_response(conn, 200)
    assert name == t.name
  end

  test "DELETE /api/v1/templates/:id deletes template", %{conn: conn, raw_key: key, template: t} do
    conn = conn |> api(key) |> delete(~p"/api/v1/templates/#{t.id}")
    assert %{"data" => %{"deleted" => true}} = json_response(conn, 200)
  end
end
