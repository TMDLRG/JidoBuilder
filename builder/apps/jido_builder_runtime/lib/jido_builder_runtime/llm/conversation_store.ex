defmodule JidoBuilderRuntime.LLM.ConversationStore do
  @moduledoc """
  Persists and loads conversation messages for LLM agent chat threads.

  Messages are grouped by `conversation_id` (a string key) and scoped to a template.
  """

  import Ecto.Query

  alias JidoBuilderCore.Repo
  alias JidoBuilderCore.Templates.ConversationMessage
  alias JidoBuilderRuntime.LLM.Conversation

  @doc "Save a single message to a conversation thread."
  @spec save_message(integer(), String.t(), map()) :: {:ok, ConversationMessage.t()} | {:error, Ecto.Changeset.t()}
  def save_message(template_id, conversation_id, message) when is_map(message) do
    %ConversationMessage{}
    |> ConversationMessage.changeset(%{
      template_id: template_id,
      conversation_id: conversation_id,
      role: message[:role] || message["role"],
      content: message[:content] || message["content"],
      tool_data: extract_tool_data(message)
    })
    |> Repo.insert()
  end

  @doc "Save multiple messages at once (e.g., user + tool_calls + assistant in one turn)."
  @spec save_messages(integer(), String.t(), [map()]) :: :ok
  def save_messages(template_id, conversation_id, messages) when is_list(messages) do
    Enum.each(messages, fn msg ->
      save_message(template_id, conversation_id, msg)
    end)

    :ok
  end

  @doc "Load a conversation thread and rebuild a Conversation struct."
  @spec load_conversation(integer(), String.t(), keyword()) :: Conversation.t()
  def load_conversation(template_id, conversation_id, opts \\ []) do
    system_prompt = Keyword.get(opts, :system)

    messages =
      ConversationMessage
      |> where([m], m.template_id == ^template_id and m.conversation_id == ^conversation_id)
      |> order_by([m], asc: m.inserted_at)
      |> Repo.all()
      |> Enum.map(&db_to_message/1)

    conv = Conversation.new(system: system_prompt)
    %{conv | messages: messages}
  end

  @doc "List all conversation threads for a template, with last message timestamp."
  @spec list_conversations(integer()) :: [%{conversation_id: String.t(), last_message_at: DateTime.t(), message_count: integer()}]
  def list_conversations(template_id) do
    ConversationMessage
    |> where([m], m.template_id == ^template_id)
    |> group_by([m], m.conversation_id)
    |> select([m], %{
      conversation_id: m.conversation_id,
      last_message_at: max(m.inserted_at),
      message_count: count(m.id)
    })
    |> order_by([m], desc: max(m.inserted_at))
    |> Repo.all()
  end

  @doc "Delete all messages in a conversation thread."
  @spec delete_conversation(integer(), String.t()) :: {integer(), nil}
  def delete_conversation(template_id, conversation_id) do
    ConversationMessage
    |> where([m], m.template_id == ^template_id and m.conversation_id == ^conversation_id)
    |> Repo.delete_all()
  end

  # Convert DB row to message map compatible with Conversation
  defp db_to_message(%ConversationMessage{role: "tool_call"} = msg) do
    %{role: "assistant", content: msg.content, tool_use: rebuild_tool_use(msg.tool_data)}
  end

  defp db_to_message(%ConversationMessage{role: "tool_result"} = msg) do
    %{role: "tool", tool_use_id: msg.tool_data["tool_use_id"], content: msg.content}
  end

  defp db_to_message(%ConversationMessage{} = msg) do
    %{role: msg.role, content: msg.content}
  end

  defp rebuild_tool_use(%{"id" => id, "name" => name, "arguments" => args}) do
    %JidoBuilderRuntime.LLM.Client.ToolUse{id: id, name: name, arguments: args}
  end

  defp rebuild_tool_use(_), do: nil

  defp extract_tool_data(%{tool_data: data}) when is_map(data), do: data
  defp extract_tool_data(%{tool_use_id: id}) when is_binary(id), do: %{"tool_use_id" => id}
  defp extract_tool_data(_), do: %{}
end
