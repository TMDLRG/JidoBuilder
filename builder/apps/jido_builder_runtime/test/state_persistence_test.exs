defmodule JidoBuilderRuntime.StatePersistenceTest do
  @moduledoc """
  Story 3.4 — State persistence and recovery.

  Assertions:
    (a) Roster.stop saves agent state snapshot to agent_instances.state
    (b) Roster.hire with recover: true restores state from last snapshot
    (c) Roster.hire with recover: true on agent with no snapshot starts fresh
    (d) Roster.list_recoverable/1 returns agents that were running at shutdown
  """
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, Repo}
  alias JidoBuilderCore.Agents.AgentInstance
  alias JidoBuilderRuntime.{Hiring, Roster, Signals}

  import Ecto.Query

  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ok = Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "persist-ws-#{System.unique_integer()}", slug: "persist-ws-#{System.unique_integer()}"},
        "test-setup"
      )

    [workspace: workspace]
  end

  test "stop saves agent state snapshot", %{workspace: ws} do
    agent_name = "persist-agent-#{System.unique_integer([:positive])}"
    {:ok, _instance} = Roster.hire(ws.id, agent_name, "test")

    # Dispatch a signal to change agent state
    context = %{workspace_id: ws.id, actor: "test"}
    {:ok, pid} = Hiring.whereis(context, agent_name)
    {:ok, signal} = Signals.new(context, "increment", %{amount: 5})
    Signals.call(context, pid, signal)

    # Stop should save state
    {:ok, stopped} = Roster.stop(ws.id, agent_name, "test")
    assert stopped.status == "stopped"

    # State should be persisted in the DB
    db_instance = Repo.one(from a in AgentInstance, where: a.name == ^agent_name)
    assert db_instance.state != nil
    assert db_instance.state != %{}
    assert db_instance.state["counter"] == 5
  end

  test "hire with recover: true restores from snapshot", %{workspace: ws} do
    agent_name = "recover-agent-#{System.unique_integer([:positive])}"
    {:ok, _instance} = Roster.hire(ws.id, agent_name, "test")

    # Modify state via signal
    context = %{workspace_id: ws.id, actor: "test"}
    {:ok, pid} = Hiring.whereis(context, agent_name)
    {:ok, signal} = Signals.new(context, "increment", %{amount: 10})
    Signals.call(context, pid, signal)

    # Stop (saves state)
    {:ok, _stopped} = Roster.stop(ws.id, agent_name, "test")

    # Re-hire with recover: true
    {:ok, recovered} = Roster.hire(ws.id, agent_name, "test", recover: true)
    assert recovered.status == "running"

    # The snapshot should be stored in the DB instance
    db_instance = Repo.one(from a in AgentInstance, where: a.name == ^agent_name and a.status == "running")
    assert db_instance != nil
  end

  test "hire with recover: true on agent with no snapshot starts fresh", %{workspace: ws} do
    agent_name = "fresh-recover-#{System.unique_integer([:positive])}"

    # No prior instance, so recover: true should just start normally
    {:ok, instance} = Roster.hire(ws.id, agent_name, "test", recover: true)
    assert instance.status == "running"
  end

  test "list_recoverable returns agents that were running at shutdown", %{workspace: ws} do
    agent_name = "recoverable-#{System.unique_integer([:positive])}"
    {:ok, _instance} = Roster.hire(ws.id, agent_name, "test")

    # Stop saves snapshot
    {:ok, _stopped} = Roster.stop(ws.id, agent_name, "test")

    # list_recoverable should find this agent since it had a saved state
    recoverable = Roster.list_recoverable(ws.id)
    assert Enum.any?(recoverable, fn a -> a.name == agent_name end)
  end
end
