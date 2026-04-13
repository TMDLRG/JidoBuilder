defmodule JidoBuilderRuntime.LLM.ToolBridgeTest do
  @moduledoc "Epic 2.3 — Tool Use Bridge tests."
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.LLM.ToolBridge
  alias JidoBuilderRuntime.LLM.Client.ToolUse

  defmodule TestEchoAction do
    use Jido.Action, name: "test_echo", description: "Echo a message", schema: [
      message: [type: :string, required: true]
    ]

    def run(params, _ctx), do: {:ok, %{echo: params[:message] || params["message"]}}
  end

  defmodule TestMathAction do
    use Jido.Action, name: "test_math", description: "Add two numbers", schema: [
      a: [type: :integer, required: true],
      b: [type: :integer, required: true]
    ]

    def run(params, _ctx) do
      a = params[:a] || params["a"]
      b = params[:b] || params["b"]
      {:ok, %{sum: a + b}}
    end
  end

  describe "actions_to_tools/1" do
    test "converts actions to tool schemas" do
      tools = ToolBridge.actions_to_tools([TestEchoAction, TestMathAction])

      assert length(tools) == 2
      assert Enum.any?(tools, fn t -> t.name == "test_echo" end)
      assert Enum.any?(tools, fn t -> t.name == "test_math" end)
    end

    test "includes description and parameters_schema" do
      [tool] = ToolBridge.actions_to_tools([TestEchoAction])

      assert tool.description == "Echo a message"
      assert tool.parameters_schema != nil
    end
  end

  describe "resolve_action/2" do
    test "finds action by tool name" do
      tool_use = %ToolUse{id: "1", name: "test_echo", arguments: %{}}

      assert {:ok, TestEchoAction} =
        ToolBridge.resolve_action(tool_use, [TestEchoAction, TestMathAction])
    end

    test "returns error for unknown tool" do
      tool_use = %ToolUse{id: "1", name: "unknown", arguments: %{}}

      assert {:error, _} =
        ToolBridge.resolve_action(tool_use, [TestEchoAction])
    end
  end

  describe "execute_tool_use/3" do
    test "executes matching action with arguments" do
      tool_use = %ToolUse{id: "1", name: "test_echo", arguments: %{"message" => "hello"}}

      assert {:ok, %{echo: "hello"}} =
        ToolBridge.execute_tool_use(tool_use, [TestEchoAction, TestMathAction])
    end

    test "executes math action" do
      tool_use = %ToolUse{id: "1", name: "test_math", arguments: %{"a" => 3, "b" => 4}}

      assert {:ok, %{sum: 7}} =
        ToolBridge.execute_tool_use(tool_use, [TestEchoAction, TestMathAction])
    end
  end

  describe "format_tool_result/2" do
    test "formats success result" do
      result = ToolBridge.format_tool_result("tool_1", {:ok, %{value: 42}})

      assert result.role == "tool"
      assert result.tool_use_id == "tool_1"
      assert String.contains?(result.content, "42")
    end

    test "formats error result" do
      result = ToolBridge.format_tool_result("tool_1", {:error, "something broke"})

      assert result.role == "tool"
      assert result.is_error == true
      assert String.contains?(result.content, "error")
    end
  end
end
