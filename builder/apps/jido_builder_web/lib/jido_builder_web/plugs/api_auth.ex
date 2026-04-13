defmodule JidoBuilderWeb.Plugs.ApiAuth do
  @moduledoc """
  Plug that authenticates API requests via Bearer token.

  Reads the `Authorization: Bearer <key>` header, validates the key via
  `JidoBuilderCore.ApiKeys.validate/1`, and injects `:api_key` and
  `:workspace_id` into conn assigns.
  """
  import Plug.Conn

  alias JidoBuilderCore.ApiKeys

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, raw_key} <- extract_bearer_token(conn),
         {:ok, api_key} <- ApiKeys.validate(raw_key) do
      ApiKeys.touch(api_key.id)

      conn
      |> assign(:api_key, api_key)
      |> assign(:workspace_id, api_key.workspace_id)
    else
      {:error, :revoked} ->
        conn |> send_json(401, %{error: "API key has been revoked"}) |> halt()

      {:error, _} ->
        conn |> send_json(401, %{error: "Invalid or missing API key"}) |> halt()
    end
  end

  defp extract_bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, String.trim(token)}
      _ -> {:error, :missing_token}
    end
  end

  defp send_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
