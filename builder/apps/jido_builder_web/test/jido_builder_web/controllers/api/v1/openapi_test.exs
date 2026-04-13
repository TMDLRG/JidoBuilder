defmodule JidoBuilderWeb.Api.V1.OpenApiTest do
  @moduledoc "Story 4.4 — OpenAPI spec endpoint."
  use JidoBuilderWeb.ConnCase, async: false

  test "GET /api/v1/openapi.json returns valid OpenAPI spec", %{conn: conn} do
    conn = get(conn, ~p"/api/v1/openapi.json")
    spec = json_response(conn, 200)

    assert spec["openapi"] == "3.0.3"
    assert spec["info"]["title"] == "JidoBuilder API"
    assert is_map(spec["paths"])
    assert Map.has_key?(spec["paths"], "/agents")
    assert Map.has_key?(spec["paths"], "/templates")
    assert Map.has_key?(spec["paths"], "/workflows")
    assert Map.has_key?(spec["paths"], "/signals")
  end

  test "OpenAPI spec includes auth scheme", %{conn: conn} do
    conn = get(conn, ~p"/api/v1/openapi.json")
    spec = json_response(conn, 200)

    assert spec["components"]["securitySchemes"]["bearerAuth"]["type"] == "http"
  end

  test "OpenAPI spec includes MCP endpoints", %{conn: conn} do
    conn = get(conn, ~p"/api/v1/openapi.json")
    spec = json_response(conn, 200)

    assert Map.has_key?(spec["paths"], "/mcp")
    assert Map.has_key?(spec["paths"], "/mcp/sse")
  end

  test "OpenAPI spec lists MCP tools", %{conn: conn} do
    conn = get(conn, ~p"/api/v1/openapi.json")
    spec = json_response(conn, 200)

    assert spec["x-mcp-tools"] != nil
    tools = spec["x-mcp-tools"]
    assert length(tools) == 13
  end
end
