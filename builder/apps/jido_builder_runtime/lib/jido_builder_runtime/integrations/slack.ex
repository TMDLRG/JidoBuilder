defmodule JidoBuilderRuntime.Integrations.Slack do
  @moduledoc "Slack webhook integration action."
  use Jido.Action,
    name: "slack_webhook",
    description: "Sends a message to a Slack channel via webhook URL",
    schema: [
      webhook_url: [type: :string, required: true],
      text: [type: :string, required: true],
      channel: [type: :string],
      username: [type: :string, default: "JidoBuilder"]
    ]

  @doc "Validate required params."
  def validate(params) do
    cond do
      !Map.get(params, :webhook_url) && !Map.get(params, "webhook_url") ->
        {:error, "webhook_url is required"}
      !Map.get(params, :text) && !Map.get(params, "text") ->
        {:error, "text is required"}
      true ->
        :ok
    end
  end

  @doc "Build a Slack webhook payload map."
  def build_payload(params) do
    %{
      "text" => get_param(params, :text),
      "channel" => get_param(params, :channel),
      "username" => get_param(params, :username, "JidoBuilder")
    }
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  @spec run(map(), map()) :: {:ok, map()} | {:error, map()}
  def run(params, _context) do
    case validate(params) do
      {:error, msg} ->
        {:error, %{code: :validation_error, message: msg}}

      :ok ->
        url = get_param(params, :webhook_url)
        payload = build_payload(params)

        case Req.post(url, json: payload, receive_timeout: 10_000, retry: false) do
          {:ok, %{status: status}} when status in 200..299 ->
            {:ok, %{status: "sent", channel: get_param(params, :channel)}}

          {:ok, %{status: status, body: body}} ->
            {:error, %{code: :slack_error, status: status, body: body}}

          {:error, reason} ->
            {:error, %{code: :slack_error, reason: inspect(reason)}}
        end
    end
  end

  defp get_param(params, key, default \\ nil) do
    Map.get(params, key) || Map.get(params, to_string(key)) || default
  end
end
