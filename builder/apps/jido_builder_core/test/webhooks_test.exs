defmodule JidoBuilderCore.WebhooksTest do
  @moduledoc "Epic 8 — Webhook system CRUD."
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, Webhooks}

  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(JidoBuilderCore.Repo)
    :ok = Ecto.Adapters.SQL.Sandbox.mode(JidoBuilderCore.Repo, {:shared, self()})

    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "webhook-ws-#{System.unique_integer()}", slug: "webhook-ws-#{System.unique_integer()}"},
        "test"
      )

    [workspace: workspace]
  end

  test "create and list webhooks", %{workspace: ws} do
    {:ok, webhook} =
      Webhooks.create(
        %{workspace_id: ws.id, name: "Test Hook", url: "https://example.com/hook", events: "signal.dispatched,agent.hired"},
        "test"
      )

    assert webhook.name == "Test Hook"
    assert webhook.status == "active"

    hooks = Webhooks.list(ws.id)
    assert Enum.any?(hooks, fn h -> h.id == webhook.id end)
  end

  test "delete webhook", %{workspace: ws} do
    {:ok, webhook} =
      Webhooks.create(
        %{workspace_id: ws.id, name: "Delete Me", url: "https://example.com/del", events: "test"},
        "test"
      )

    {:ok, _} = Webhooks.delete(webhook.id, "test")

    hooks = Webhooks.list(ws.id)
    refute Enum.any?(hooks, fn h -> h.id == webhook.id end)
  end
end
