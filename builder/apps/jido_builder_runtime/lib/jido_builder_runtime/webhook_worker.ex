defmodule JidoBuilderRuntime.WebhookWorker do
  @moduledoc """
  Webhook delivery worker with exponential backoff retry.

  Uses Task.Supervisor for async delivery with retry support.
  Max 5 attempts with delays: 1s, 2s, 4s, 8s, 16s.
  """

  @max_attempts 5

  @doc "Deliver a webhook with retry support."
  def deliver(webhook, event_type, payload, attempt \\ 1) do
    Task.Supervisor.start_child(
      JidoBuilderRuntime.TaskSupervisor,
      fn -> do_deliver(webhook, event_type, payload, attempt) end
    )
  end

  defp do_deliver(webhook, event_type, payload, attempt) do
    alias JidoBuilderCore.Webhooks

    result =
      Req.post(webhook.url,
        json: %{event: event_type, payload: payload, timestamp: DateTime.utc_now()},
        headers: build_headers(webhook),
        receive_timeout: 10_000,
        retry: false
      )

    case result do
      {:ok, %{status: status}} when status in 200..299 ->
        Webhooks.log_delivery(webhook.id, event_type, "delivered", %{
          response_code: status,
          attempt: attempt
        })

      {:ok, %{status: status}} ->
        handle_failure(webhook, event_type, payload, attempt, "HTTP #{status}")

      {:error, reason} ->
        handle_failure(webhook, event_type, payload, attempt, inspect(reason))
    end
  end

  defp handle_failure(webhook, event_type, payload, attempt, error_msg) do
    alias JidoBuilderCore.Webhooks

    if attempt < @max_attempts do
      delay = Webhooks.retry_delay_ms(attempt)

      Webhooks.log_delivery(webhook.id, event_type, "failed", %{
        error: error_msg,
        attempt: attempt,
        next_retry_at: DateTime.utc_now() |> DateTime.add(delay, :millisecond) |> DateTime.to_iso8601()
      })

      Process.sleep(delay)
      do_deliver(webhook, event_type, payload, attempt + 1)
    else
      Webhooks.log_delivery(webhook.id, event_type, "failed", %{
        error: error_msg,
        attempt: attempt,
        final: true
      })
    end
  end

  defp build_headers(%{secret: nil}), do: []
  defp build_headers(%{secret: s}) when is_binary(s) and s != "", do: [{"x-webhook-secret", s}]
  defp build_headers(_), do: []
end
