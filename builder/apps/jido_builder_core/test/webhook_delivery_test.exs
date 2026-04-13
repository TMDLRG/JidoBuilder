defmodule JidoBuilderCore.WebhookDeliveryTest do
  @moduledoc "Story 8.1 — Webhook delivery logs and retry."
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, Webhooks, Repo}
  alias JidoBuilderCore.Webhooks.DeliveryLog

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "wh-test-#{System.unique_integer()}", slug: "wh-test-#{System.unique_integer()}"},
        "test"
      )

    {:ok, webhook} =
      Webhooks.create(
        %{
          "workspace_id" => workspace.id,
          "name" => "test-hook",
          "url" => "https://httpbin.org/post",
          "events" => "agent.hired,agent.stopped",
          "status" => "active"
        },
        "test"
      )

    %{workspace: workspace, webhook: webhook}
  end

  test "log_delivery creates a delivery log entry", %{webhook: webhook} do
    {:ok, log} =
      Webhooks.log_delivery(webhook.id, "agent.hired", "delivered", %{response_code: 200})

    assert log.webhook_id == webhook.id
    assert log.event_type == "agent.hired"
    assert log.status == "delivered"
    assert log.details["response_code"] == 200
  end

  test "list_deliveries returns logs for a webhook", %{webhook: webhook} do
    {:ok, _} = Webhooks.log_delivery(webhook.id, "agent.hired", "delivered", %{})
    {:ok, _} = Webhooks.log_delivery(webhook.id, "agent.stopped", "failed", %{error: "timeout"})

    logs = Webhooks.list_deliveries(webhook.id)
    assert length(logs) == 2
  end

  test "failed delivery creates log with failed status and retry info", %{webhook: webhook} do
    {:ok, log} =
      Webhooks.log_delivery(webhook.id, "agent.hired", "failed", %{
        error: "connection refused",
        attempt: 1,
        next_retry_at: DateTime.utc_now() |> DateTime.add(1, :second)
      })

    assert log.status == "failed"
    assert log.details["attempt"] == 1
    assert log.details["next_retry_at"]
  end

  test "retry backoff timing doubles each attempt", %{webhook: _webhook} do
    delays = for attempt <- 1..5, do: Webhooks.retry_delay_ms(attempt)

    assert delays == [1_000, 2_000, 4_000, 8_000, 16_000]
  end
end
