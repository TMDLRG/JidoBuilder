defmodule JidoBuilderCore.DeadLetterQueueTest do
  @moduledoc "Story 7.3 — Dead Letter Queue tests (DD TDD: written before implementation)."
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, DeadLetterQueue, Repo}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "dlq-ws-#{System.unique_integer([:positive])}", slug: "dlq-ws-#{System.unique_integer([:positive])}"},
        "test"
      )

    %{workspace: workspace}
  end

  describe "enqueue/1" do
    test "creates a DLQ entry with pending status", %{workspace: ws} do
      {:ok, entry} =
        DeadLetterQueue.enqueue(%{
          workspace_id: ws.id,
          agent_name: "test-agent",
          signal_type: "signal.dispatch",
          payload: %{"key" => "value"},
          error: "timeout after 5000ms"
        })

      assert entry.workspace_id == ws.id
      assert entry.agent_name == "test-agent"
      assert entry.signal_type == "signal.dispatch"
      assert entry.payload == %{"key" => "value"}
      assert entry.error == "timeout after 5000ms"
      assert entry.status == "pending"
    end
  end

  describe "list/1" do
    test "returns entries for a workspace", %{workspace: ws} do
      {:ok, _} =
        DeadLetterQueue.enqueue(%{
          workspace_id: ws.id,
          agent_name: "agent-a",
          signal_type: "ping",
          payload: %{},
          error: "boom"
        })

      {:ok, _} =
        DeadLetterQueue.enqueue(%{
          workspace_id: ws.id,
          agent_name: "agent-b",
          signal_type: "pong",
          payload: %{},
          error: "crash"
        })

      entries = DeadLetterQueue.list(ws.id)
      assert length(entries) >= 2
      assert Enum.all?(entries, fn e -> e.workspace_id == ws.id end)
    end
  end

  describe "retry/1" do
    test "marks entry as retried", %{workspace: ws} do
      {:ok, entry} =
        DeadLetterQueue.enqueue(%{
          workspace_id: ws.id,
          agent_name: "retry-agent",
          signal_type: "test.signal",
          payload: %{},
          error: "failed"
        })

      {:ok, updated} = DeadLetterQueue.retry(entry.id)
      assert updated.status == "retried"
    end
  end

  describe "purge/1" do
    test "marks entry as purged", %{workspace: ws} do
      {:ok, entry} =
        DeadLetterQueue.enqueue(%{
          workspace_id: ws.id,
          agent_name: "purge-agent",
          signal_type: "test.signal",
          payload: %{},
          error: "failed"
        })

      {:ok, updated} = DeadLetterQueue.purge(entry.id)
      assert updated.status == "purged"
    end
  end
end
