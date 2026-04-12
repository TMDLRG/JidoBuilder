defmodule JidoBuilderWeb.HealthControllerTest do
  use JidoBuilderWeb.ConnCase, async: false

  test "GET /healthz returns 200 ok", %{conn: conn} do
    conn = get(conn, "/healthz")
    assert conn.status == 200
    assert conn.resp_body == "ok"
  end

  test "GET /readyz returns 200 when deps are up", %{conn: conn} do
    conn = get(conn, "/readyz")
    assert conn.status == 200
    assert conn.resp_body == "ready"
  end
end
