defmodule JidoBuilderCore.Webhooks do
  @moduledoc "Webhook CRUD and delivery."
  import Ecto.Query

  alias JidoBuilderCore.{Audit, Repo}
  alias JidoBuilderCore.Webhooks.{Webhook, DeliveryLog}

  def list(workspace_id) do
    Webhook
    |> where([w], w.workspace_id == ^workspace_id)
    |> order_by([w], desc: w.inserted_at)
    |> Repo.all()
  end

  def create(attrs, actor) do
    %Webhook{}
    |> Webhook.changeset(attrs)
    |> Repo.insert()
    |> maybe_audit(actor, "webhooks.create")
  end

  def delete(webhook_id, actor) do
    case Repo.get(Webhook, webhook_id) do
      nil -> {:error, :not_found}
      webhook ->
        Repo.delete(webhook)
        |> maybe_audit(actor, "webhooks.delete")
    end
  end

  @doc "Delivers a webhook event to all matching active webhooks."
  def deliver(workspace_id, event_type, payload) do
    list(workspace_id)
    |> Enum.filter(fn w -> w.status == "active" and event_type in String.split(w.events, ",") end)
    |> Enum.map(fn w ->
      Task.start(fn ->
        Req.post(w.url,
          json: %{event: event_type, payload: payload, timestamp: DateTime.utc_now()},
          headers: webhook_headers(w),
          receive_timeout: 10_000,
          retry: false
        )
      end)
    end)
  end

  @doc "Log a delivery attempt for a webhook."
  def log_delivery(webhook_id, event_type, status, details \\ %{}) do
    string_details =
      details
      |> Enum.map(fn {k, v} -> {to_string(k), v} end)
      |> Map.new()

    %DeliveryLog{}
    |> DeliveryLog.changeset(%{
      webhook_id: webhook_id,
      event_type: event_type,
      status: status,
      details: string_details
    })
    |> Repo.insert()
  end

  @doc "List delivery logs for a webhook."
  def list_deliveries(webhook_id) do
    DeliveryLog
    |> where([d], d.webhook_id == ^webhook_id)
    |> order_by([d], desc: d.inserted_at)
    |> Repo.all()
  end

  @doc "Calculate retry delay in milliseconds using exponential backoff: 1s, 2s, 4s, 8s, 16s."
  def retry_delay_ms(attempt) when is_integer(attempt) and attempt > 0 do
    trunc(:math.pow(2, attempt - 1) * 1_000)
  end

  defp webhook_headers(%{secret: nil}), do: []
  defp webhook_headers(%{secret: secret}) when is_binary(secret) and secret != "" do
    [{"x-webhook-secret", secret}]
  end
  defp webhook_headers(_), do: []

  defp maybe_audit({:ok, record} = ok, actor, action) do
    _ = Audit.log(actor, action, record, %{})
    ok
  end
  defp maybe_audit(error, _actor, _action), do: error
end
