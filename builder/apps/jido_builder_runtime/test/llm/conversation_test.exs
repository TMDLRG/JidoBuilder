defmodule JidoBuilderRuntime.LLM.ConversationTest do
  @moduledoc "Epic 2.4 — Conversation management tests."
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.LLM.Conversation
  alias JidoBuilderRuntime.LLM.Client.{Response, ToolUse}

  describe "new/1" do
    test "creates empty conversation" do
      conv = Conversation.new()
      assert conv.messages == []
      assert conv.system == nil
    end

    test "accepts system prompt" do
      conv = Conversation.new(system: "You are helpful.")
      assert conv.system == "You are helpful."
    end
  end

  describe "add_user/2" do
    test "appends user message" do
      conv = Conversation.new()
        |> Conversation.add_user("Hello")

      assert Conversation.length(conv) == 1
      [msg] = conv.messages
      assert msg.role == "user"
      assert msg.content == "Hello"
    end
  end

  describe "add_assistant/2" do
    test "appends assistant message" do
      conv = Conversation.new()
        |> Conversation.add_user("Hi")
        |> Conversation.add_assistant("Hello!")

      assert Conversation.length(conv) == 2
    end
  end

  describe "add_response/2" do
    test "adds text response" do
      response = %Response{
        role: "assistant",
        content: "I can help!",
        tool_use: nil,
        usage: %{input_tokens: 10, output_tokens: 5}
      }

      conv = Conversation.new()
        |> Conversation.add_user("Help me")
        |> Conversation.add_response(response)

      assert Conversation.length(conv) == 2
      assert conv.total_tokens == 15
    end

    test "adds tool_use response" do
      tool_use = %ToolUse{id: "t1", name: "echo", arguments: %{"msg" => "hi"}}
      response = %Response{
        role: "assistant",
        content: nil,
        tool_use: tool_use,
        usage: %{input_tokens: 10, output_tokens: 8}
      }

      conv = Conversation.new()
        |> Conversation.add_user("Echo hello")
        |> Conversation.add_response(response)

      assert Conversation.length(conv) == 2
      last_msg = List.last(conv.messages)
      assert last_msg.tool_use == tool_use
    end
  end

  describe "to_messages/1" do
    test "includes system message when set" do
      conv = Conversation.new(system: "Be helpful")
        |> Conversation.add_user("Hi")

      msgs = Conversation.to_messages(conv)
      assert length(msgs) == 2
      assert List.first(msgs).role == "system"
    end

    test "excludes system when not set" do
      conv = Conversation.new()
        |> Conversation.add_user("Hi")

      msgs = Conversation.to_messages(conv)
      assert length(msgs) == 1
    end
  end

  describe "truncate/1" do
    test "truncates when exceeding max_messages" do
      conv = Conversation.new(max_messages: 3)

      conv = Enum.reduce(1..5, conv, fn i, acc ->
        Conversation.add_user(acc, "Message #{i}")
      end)

      assert Conversation.length(conv) == 3
    end

    test "preserves recent messages" do
      conv = Conversation.new(max_messages: 2)
        |> Conversation.add_user("Old message")
        |> Conversation.add_user("Newer message")
        |> Conversation.add_user("Newest message")

      [first, second] = conv.messages
      assert first.content == "Newer message"
      assert second.content == "Newest message"
    end
  end

  describe "add_tool_result/3" do
    test "adds tool result message" do
      conv = Conversation.new()
        |> Conversation.add_tool_result("tool_1", "{\"result\": 42}")

      [msg] = conv.messages
      assert msg.role == "tool"
      assert msg.tool_use_id == "tool_1"
    end
  end
end
