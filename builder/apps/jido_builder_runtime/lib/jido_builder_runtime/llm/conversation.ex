defmodule JidoBuilderRuntime.LLM.Conversation do
  @moduledoc """
  Conversation management for LLM agents.

  Projects Thread entries into LLM message format, manages context
  window limits, and handles system prompt injection.
  """

  alias JidoBuilderRuntime.LLM.Client.{Response, ToolUse}

  defstruct [
    messages: [],
    system: nil,
    max_messages: 50,
    total_tokens: 0
  ]

  @type t :: %__MODULE__{
          messages: [map()],
          system: String.t() | nil,
          max_messages: pos_integer(),
          total_tokens: non_neg_integer()
        }

  @doc "Create a new conversation with optional system prompt."
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      system: Keyword.get(opts, :system),
      max_messages: Keyword.get(opts, :max_messages, 50),
      messages: [],
      total_tokens: 0
    }
  end

  @doc "Add a user message."
  @spec add_user(t(), String.t()) :: t()
  def add_user(%__MODULE__{} = conv, content) when is_binary(content) do
    add_message(conv, %{role: "user", content: content})
  end

  @doc "Add an assistant text response."
  @spec add_assistant(t(), String.t()) :: t()
  def add_assistant(%__MODULE__{} = conv, content) when is_binary(content) do
    add_message(conv, %{role: "assistant", content: content})
  end

  @doc "Add an assistant tool_use response."
  @spec add_tool_use(t(), ToolUse.t()) :: t()
  def add_tool_use(%__MODULE__{} = conv, %ToolUse{} = tool_use) do
    add_message(conv, %{
      role: "assistant",
      content: nil,
      tool_use: tool_use
    })
  end

  @doc "Add a tool result message."
  @spec add_tool_result(t(), String.t(), String.t()) :: t()
  def add_tool_result(%__MODULE__{} = conv, tool_use_id, result) do
    add_message(conv, %{
      role: "tool",
      tool_use_id: tool_use_id,
      content: result
    })
  end

  @doc "Add an LLM Response to the conversation."
  @spec add_response(t(), Response.t()) :: t()
  def add_response(%__MODULE__{} = conv, %Response{} = response) do
    conv =
      if response.usage do
        tokens = (response.usage[:input_tokens] || 0) + (response.usage[:output_tokens] || 0)
        %{conv | total_tokens: conv.total_tokens + tokens}
      else
        conv
      end

    case response.tool_use do
      nil -> add_assistant(conv, response.content || "")
      tool_use -> add_tool_use(conv, tool_use)
    end
  end

  @doc "Get messages formatted for LLM API call (with system message prepended if set)."
  @spec to_messages(t()) :: [map()]
  def to_messages(%__MODULE__{messages: msgs, system: system}) do
    case system do
      nil -> msgs
      sys -> [%{role: "system", content: sys} | msgs]
    end
  end

  @doc "Get just the message list (without system)."
  @spec messages(t()) :: [map()]
  def messages(%__MODULE__{messages: msgs}), do: msgs

  @doc "Count of messages in the conversation."
  @spec length(t()) :: non_neg_integer()
  def length(%__MODULE__{messages: msgs}), do: Kernel.length(msgs)

  @doc "Truncate older messages to stay within limits."
  @spec truncate(t()) :: t()
  def truncate(%__MODULE__{messages: msgs, max_messages: max} = conv) do
    if Kernel.length(msgs) > max do
      # Keep the most recent messages, always preserving the first user message
      truncated = Enum.take(msgs, -max)
      %{conv | messages: truncated}
    else
      conv
    end
  end

  # -- Private --

  defp add_message(%__MODULE__{} = conv, message) do
    %{conv | messages: conv.messages ++ [message]}
    |> truncate()
  end
end
