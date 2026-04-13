defmodule JidoBuilderRuntime.Actions.WebhookCall do
  @moduledoc "POST a JSON payload to a webhook URL."
  use Jido.Action,
    name: "webhook_call",
    description: "Sends a JSON POST to a webhook endpoint",
    schema: [
      url: [type: :string, required: true],
      payload: [type: :map, required: true],
      headers: [type: :map, default: %{}],
      timeout: [type: :integer, default: 10_000]
    ]

  @spec run(map(), map()) :: {:ok, map()} | {:error, map()}
  def run(params, _context) do
    url = get_param(params, :url)
    payload = get_param(params, :payload, %{})
    headers = get_param(params, :headers, %{}) |> Map.to_list()
    timeout = get_param(params, :timeout, 10_000)

    case Req.post(url,
           json: payload,
           headers: headers,
           receive_timeout: timeout,
           retry: false
         ) do
      {:ok, %Req.Response{status: status, body: body}} ->
        {:ok, %{status: status, body: body, url: url, delivered: true}}

      {:error, %{reason: reason}} ->
        {:error, %{code: :webhook_error, url: url, reason: inspect(reason)}}

      {:error, reason} ->
        {:error, %{code: :webhook_error, url: url, reason: inspect(reason)}}
    end
  end

  defp get_param(params, key, default \\ nil) do
    Map.get(params, key) || Map.get(params, to_string(key)) || default
  end
end
