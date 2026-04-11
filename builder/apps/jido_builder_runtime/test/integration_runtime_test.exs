defmodule JidoBuilderRuntime.IntegrationRuntimeTest do
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.{Context, Hiring}

  defmodule MinimalRuntimeAgent do
    use Jido.Agent,
      name: "runtime_minimal",
      description: "minimal runtime agent",
      schema: [counter: [type: :integer, default: 0]]
  end

  test "hire/list/count/whereis/stop uses real Jido runtime" do
    context = %{workspace_id: 1, actor: "integration", partition: :runtime_test}
    agent_id = "runtime-agent-#{System.unique_integer([:positive])}"

    assert {:ok, pid} = Hiring.start(context, MinimalRuntimeAgent, id: agent_id)
    assert is_pid(pid)

    assert {:ok, 1} = Hiring.count(context)
    assert {:ok, [{^agent_id, ^pid}]} = Hiring.list(context)
    assert {:ok, ^pid} = Hiring.whereis(context, agent_id)

    assert :ok = Hiring.stop(context, agent_id)
    assert {:error, %{code: :not_found}} = Hiring.whereis(context, agent_id)
  end

  test "context validation requires positive workspace and actor" do
    assert {:error, %{code: :invalid_context}} = Context.validate(%{workspace_id: 0, actor: "x"})
    assert {:error, %{code: :invalid_context}} = Context.validate(%{workspace_id: 1, actor: ""})
    assert {:ok, %{jido_instance: Jido}} = Context.validate(%{workspace_id: 1, actor: "ok"})
  end
end
