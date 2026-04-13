defmodule JidoBuilderRuntime.SignalsTimedCallTest do
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, Repo}
  alias JidoBuilderRuntime.{Hiring, Signals}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "TimedCall", slug: "tc-#{System.unique_integer([:positive])}"},
        "tester"
      )

    context = %{workspace_id: workspace.id, actor: "tester", partition: :timed_call_test}

    %{workspace: workspace, context: context}
  end

  defmodule TimedCallAgent do
    use Jido.Agent,
      name: "timed_call_agent",
      description: "agent for timed call tests",
      schema: [counter: [type: :integer, default: 0]]
  end

  describe "Signals.timed_call/4" do
    test "returns {:ok, agent_state, elapsed_ms} with timing on dispatch", %{
      context: context
    } do
      agent_id = "timed-call-#{System.unique_integer([:positive])}"
      {:ok, _pid} = Hiring.start(context, TimedCallAgent, id: agent_id)
      {:ok, server} = Hiring.whereis(context, agent_id)

      {:ok, signal} = Signals.new(context, "ping", %{message: "hello"})

      # The agent may not route "ping", but the call itself will still return
      # a result (success or error) with timing information
      result = Signals.timed_call(context, server, signal)

      case result do
        {:ok, agent_state, elapsed_ms} ->
          assert is_map(agent_state) or is_struct(agent_state)
          assert is_integer(elapsed_ms)
          assert elapsed_ms >= 0

        {:error, _error, elapsed_ms} ->
          # Even on error, timing is captured
          assert is_integer(elapsed_ms)
          assert elapsed_ms >= 0
      end
    end

    test "always returns elapsed_ms even on failure", %{context: context} do
      # Use a dead process to force failure
      fake_pid = spawn(fn -> :ok end)
      Process.exit(fake_pid, :kill)
      :timer.sleep(10)

      {:ok, signal} = Signals.new(context, "ping", %{})

      result = Signals.timed_call(context, fake_pid, signal)

      assert {:error, _error, elapsed_ms} = result
      assert is_integer(elapsed_ms)
      assert elapsed_ms >= 0
    end

    test "elapsed_ms reflects actual wall-clock time", %{context: context} do
      agent_id = "timed-wall-#{System.unique_integer([:positive])}"
      {:ok, _pid} = Hiring.start(context, TimedCallAgent, id: agent_id)
      {:ok, server} = Hiring.whereis(context, agent_id)

      {:ok, signal} = Signals.new(context, "ping", %{})

      {wall_us, result} = :timer.tc(fn -> Signals.timed_call(context, server, signal) end)
      wall_ms = div(wall_us, 1_000)

      # Extract elapsed_ms from either success or error tuple
      elapsed_ms =
        case result do
          {:ok, _, ms} -> ms
          {:error, _, ms} -> ms
        end

      # Elapsed should be reasonably close to wall clock
      assert elapsed_ms <= wall_ms + 10
    end
  end
end
