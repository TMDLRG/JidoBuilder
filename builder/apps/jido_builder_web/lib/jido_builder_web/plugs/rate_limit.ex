defmodule JidoBuilderWeb.Plugs.RateLimit do
  @moduledoc """
  Plug that rate-limits API requests using Hammer.

  Reads `rate_limit` from the api_key assign (set by ApiAuth plug)
  and enforces requests/minute per API key.
  """
  import Plug.Conn

  @default_limit 100
  @window_ms 60_000

  def init(opts), do: opts

  def call(conn, _opts) do
    api_key = conn.assigns[:api_key]
    limit = if api_key, do: api_key.rate_limit || @default_limit, else: @default_limit
    bucket = "api:#{api_key && api_key.id || "anonymous"}"

    case Hammer.check_rate(bucket, @window_ms, limit) do
      {:allow, _count} ->
        conn

      {:deny, _limit} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(429, Jason.encode!(%{error: "Rate limit exceeded", limit: limit}))
        |> halt()
    end
  end
end
