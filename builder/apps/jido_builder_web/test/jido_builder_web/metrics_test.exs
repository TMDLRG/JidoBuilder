defmodule JidoBuilderWeb.MetricsTest do
  @moduledoc "7.12 — Prometheus /metrics returns text/plain with Phoenix summaries."
  use JidoBuilderWeb.ConnCase, async: false

  test "GET /metrics returns 200 with prometheus text", %{conn: conn} do
    conn = get(conn, "/metrics")
    assert conn.status == 200
    assert get_resp_header(conn, "content-type") |> hd() =~ "text/plain"
  end
end
