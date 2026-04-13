defmodule JidoBuilderRuntime.Integrations.HttpWebhook do
  @moduledoc "Generic outbound HTTP webhook action."
  use Jido.Action,
    name: "http_webhook",
    description: "Sends a generic HTTP webhook with configurable method and headers",
    schema: [
      url: [type: :string, required: true],
      method: [type: :string, default: "POST"],
      payload: [type: :map, default: %{}],
      headers: [type: :map, default: %{}],
      timeout: [type: :integer, default: 10_000]
    ]

  @spec run(map(), map()) :: {:ok, map()} | {:error, map()}
  def run(params, _context) do
    url = get_param(params, :url)
    method = get_param(params, :method, "POST") |> String.downcase() |> String.to_atom()
    payload = get_param(params, :payload, %{})
    headers = get_param(params, :headers, %{}) |> Map.to_list()
    timeout = get_param(params, :timeout, 10_000)

    opts = [json: payload, headers: headers, receive_timeout: timeout, retry: false]

    result =
      case method do
        :post -> Req.post(url, opts)
        :put -> Req.put(url, opts)
        :patch -> Req.patch(url, opts)
        :delete -> Req.delete(url, Keyword.drop(opts, [:json]))
        _ -> Req.post(url, opts)
      end

    case result do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, %{status: status, body: body, url: url}}

      {:ok, %{status: status, body: body}} ->
        {:error, %{code: :http_error, status: status, body: body}}

      {:error, reason} ->
        {:error, %{code: :http_error, reason: inspect(reason)}}
    end
  end

  defp get_param(params, key, default \\ nil) do
    Map.get(params, key) || Map.get(params, to_string(key)) || default
  end
end
