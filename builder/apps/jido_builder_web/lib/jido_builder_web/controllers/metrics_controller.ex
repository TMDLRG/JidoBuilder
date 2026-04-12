defmodule JidoBuilderWeb.MetricsController do
  @moduledoc """
  7.12 — Serves Prometheus-format metrics from TelemetryMetricsPrometheus.Core.
  Mounted on `/metrics` in the API scope (no auth).
  """
  use JidoBuilderWeb, :controller

  def index(conn, _params) do
    metrics = TelemetryMetricsPrometheus.Core.scrape()

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, metrics)
  end
end
