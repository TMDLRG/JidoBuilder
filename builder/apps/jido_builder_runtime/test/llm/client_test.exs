defmodule JidoBuilderRuntime.LLM.ClientTest do
  @moduledoc "Epic 2.1 — LLM Client behaviour and Mock provider tests."
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.LLM.Client
  alias JidoBuilderRuntime.LLM.Providers.Mock

  describe "Mock provider — chat/2" do
    test "returns a text response" do
      config = Mock.default_config()

      result = Mock.chat([
        %{role: "user", content: "Hello"}
      ], config)

      assert {:ok, response} = result
      assert response.content != nil
      assert is_binary(response.content)
      assert response.role == "assistant"
    end

    test "accepts system message" do
      config = Mock.default_config()

      result = Mock.chat([
        %{role: "system", content: "You are helpful."},
        %{role: "user", content: "Hi"}
      ], config)

      assert {:ok, response} = result
      assert response.role == "assistant"
    end

    test "respects custom response in config" do
      config = Mock.default_config()
        |> Map.put(:mock_response, "Custom response text")

      {:ok, response} = Mock.chat([%{role: "user", content: "test"}], config)
      assert response.content == "Custom response text"
    end
  end

  describe "Mock provider — chat_with_tools/3" do
    test "returns tool_use response when tools are available" do
      config = Mock.default_config()
        |> Map.put(:mock_tool_use, %{
          name: "echo",
          arguments: %{"message" => "hello"}
        })

      tools = [
        %{name: "echo", description: "Echo back", parameters_schema: %{}}
      ]

      result = Mock.chat_with_tools([
        %{role: "user", content: "Echo hello"}
      ], tools, config)

      assert {:ok, response} = result
      assert response.tool_use != nil
      assert response.tool_use.name == "echo"
    end

    test "returns text response when no tool_use configured" do
      config = Mock.default_config()

      tools = [
        %{name: "echo", description: "Echo back", parameters_schema: %{}}
      ]

      result = Mock.chat_with_tools([
        %{role: "user", content: "Just respond"}
      ], tools, config)

      assert {:ok, response} = result
      assert response.content != nil
    end
  end

  describe "Mock provider — stream/2" do
    test "returns a stream of chunks" do
      config = Mock.default_config()
        |> Map.put(:mock_response, "Hello world")

      result = Mock.stream([%{role: "user", content: "Hi"}], config)

      assert {:ok, stream} = result
      chunks = Enum.to_list(stream)
      assert length(chunks) > 0
      full_text = Enum.map_join(chunks, "", & &1.content)
      assert full_text == "Hello world"
    end
  end

  describe "Client.chat/3 — dispatch to provider" do
    test "dispatches to mock provider" do
      config = %{
        provider: :mock,
        model: "mock-model",
        mock_response: "Dispatched response"
      }

      {:ok, response} = Client.chat([%{role: "user", content: "test"}], config)
      assert response.content == "Dispatched response"
    end
  end

  describe "Client.chat_with_tools/4 — dispatch" do
    test "dispatches tool call to mock provider" do
      config = %{
        provider: :mock,
        model: "mock-model",
        mock_tool_use: %{name: "test_tool", arguments: %{"key" => "val"}}
      }

      tools = [%{name: "test_tool", description: "A test", parameters_schema: %{}}]

      {:ok, response} = Client.chat_with_tools(
        [%{role: "user", content: "use the tool"}],
        tools,
        config
      )

      assert response.tool_use.name == "test_tool"
    end
  end

  describe "Client — provider resolution" do
    test "resolves :mock provider" do
      assert Client.provider_module(:mock) == Mock
    end

    test "resolves :anthropic provider" do
      assert Client.provider_module(:anthropic) == JidoBuilderRuntime.LLM.Providers.Anthropic
    end

    test "resolves :openai provider" do
      assert Client.provider_module(:openai) == JidoBuilderRuntime.LLM.Providers.OpenAI
    end
  end

  describe "Response struct" do
    test "creates a text response" do
      resp = %Client.Response{
        role: "assistant",
        content: "Hello",
        tool_use: nil,
        usage: %{input_tokens: 10, output_tokens: 5}
      }

      assert resp.content == "Hello"
      assert resp.tool_use == nil
    end

    test "creates a tool_use response" do
      resp = %Client.Response{
        role: "assistant",
        content: nil,
        tool_use: %Client.ToolUse{
          id: "tool_1",
          name: "echo",
          arguments: %{"message" => "hi"}
        }
      }

      assert resp.tool_use.name == "echo"
    end
  end
end
