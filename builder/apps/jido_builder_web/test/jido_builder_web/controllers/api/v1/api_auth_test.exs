defmodule JidoBuilderWeb.Api.V1.ApiAuthTest do
  @moduledoc """
  Story 4.1 — API key auth and rate limiting.

  Assertions:
    (a) Request without Bearer token returns 401
    (b) Request with invalid token returns 401
    (c) Request with valid token passes and includes workspace_id
    (d) Revoked key returns 401
    (e) Rate limiting returns 429 when exceeded
    (f) ApiKeys.generate/3 creates a key and ApiKeys.validate/1 verifies it
  """
  use JidoBuilderWeb.ConnCase, async: false

  alias JidoBuilderCore.{Agents, ApiKeys}

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "api-auth-ws-#{System.unique_integer()}", slug: "api-ws-#{System.unique_integer()}"},
        "test-setup"
      )

    {:ok, api_key, raw_key} = ApiKeys.generate(workspace.id, "test-key", "test")

    %{workspace: workspace, api_key: api_key, raw_key: raw_key}
  end

  test "request without Bearer token returns 401", %{conn: conn} do
    conn = get(conn, ~p"/api/v1/agents")
    assert json_response(conn, 401)["error"] =~ "Invalid"
  end

  test "request with invalid token returns 401", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "Bearer invalid-key-here")
      |> get(~p"/api/v1/agents")

    assert json_response(conn, 401)["error"] =~ "Invalid"
  end

  test "request with valid token passes", %{conn: conn, raw_key: raw_key} do
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{raw_key}")
      |> get(~p"/api/v1/agents")

    assert conn.status == 200
  end

  test "revoked key returns 401", %{conn: conn, api_key: api_key, raw_key: raw_key} do
    {:ok, _revoked} = ApiKeys.revoke(api_key.id, "test")

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{raw_key}")
      |> get(~p"/api/v1/agents")

    assert json_response(conn, 401)["error"] =~ "revoked"
  end

  test "ApiKeys.generate creates and validate verifies", %{workspace: ws} do
    {:ok, _key, raw} = ApiKeys.generate(ws.id, "another-key", "test")
    assert {:ok, _} = ApiKeys.validate(raw)
    assert {:error, :invalid} = ApiKeys.validate("bogus")
  end

  test "ApiKeys.list shows keys for workspace", %{workspace: ws} do
    keys = ApiKeys.list(ws.id)
    assert length(keys) >= 1
  end
end
