defmodule JidoBuilderRuntime.Actions.LlmChat do
  @moduledoc """
  LLM Chat Action with agentic tool-use loop.

  Routes a user message through an LLM provider, handling multi-turn
  tool-use calls via the ToolBridge. The loop continues until the LLM
  returns a final text response or the iteration ceiling is reached.

  ## Parameters

    * `message` - The user's chat input (required)
    * `conversation` - An existing `%Conversation{}` struct or nil (optional)
    * `llm_config` - Provider config map: provider, model, api_key, etc. (required)
    * `tool_modules` - List of Action modules to expose as LLM tools (optional)
    * `max_iterations` - Ceiling on tool-use loop iterations, default 10 (optional)

  ## Returns

    * `reply` - The LLM's final text response
    * `conversation` - Updated conversation with full history
    * `tool_calls` - Log of tool invocations during this turn
    * `iterations` - Number of LLM calls made
  """

  use Jido.Action,
    name: "llm_chat",
    description: "Send a message through an LLM with agentic tool-use loop",
    schema: [
      message: [type: :string, required: true],
      conversation: [type: :any, default: nil],
      llm_config: [type: :map, required: true],
      tool_modules: [type: {:list, :atom}, default: []],
      max_iterations: [type: :integer, default: 10]
    ]

  alias JidoBuilderRuntime.LLM.{Client, Conversation, ToolBridge}
  alias JidoBuilderRuntime.LLM.Client.ToolUse

  @impl true
  def run(params, _context) do
    conv =
      case params[:conversation] do
        %Conversation{} = c -> c
        _ -> Conversation.new(system: get_in(params, [:llm_config, :system]))
      end

    conv = Conversation.add_user(conv, params.message)
    tools = ToolBridge.actions_to_tools(params.tool_modules || [])
    max = params[:max_iterations] || 10

    case agentic_loop(conv, tools, params.tool_modules || [], params.llm_config, [], 0, max) do
      {:ok, reply, updated_conv, tool_log, iterations} ->
        {:ok, %{
          reply: reply,
          conversation: updated_conv,
          tool_calls: tool_log,
          iterations: iterations
        }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Recursive agentic loop:
  # 1. Call LLM (with tools if any)
  # 2. If response has tool_use → execute action → feed result back → recurse
  # 3. If response has text content → done
  # 4. If max iterations reached → error
  defp agentic_loop(conv, tools, modules, config, tool_log, iteration, max)
       when iteration < max do
    result =
      if tools == [] do
        Client.chat(Conversation.to_messages(conv), config)
      else
        Client.chat_with_tools(Conversation.to_messages(conv), tools, config)
      end

    case result do
      {:ok, %{tool_use: %ToolUse{} = tu} = response} ->
        # Add the assistant's tool_use message to conversation
        conv = Conversation.add_response(conv, response)

        # Execute the tool via ToolBridge
        exec_result = ToolBridge.execute_tool_use(tu, modules)
        tool_result = ToolBridge.format_tool_result(tu.id, exec_result)

        # Add tool result to conversation
        conv = Conversation.add_tool_result(conv, tu.id, tool_result.content)

        # Log the tool call
        log_entry = %{
          tool: tu.name,
          arguments: tu.arguments,
          result: tool_result.content,
          is_error: Map.get(tool_result, :is_error, false)
        }

        agentic_loop(
          conv, tools, modules, config,
          tool_log ++ [log_entry],
          iteration + 1, max
        )

      {:ok, %{content: text} = response} when is_binary(text) ->
        conv = Conversation.add_response(conv, response)
        {:ok, text, conv, tool_log, iteration + 1}

      {:ok, %{content: nil} = response} ->
        # No content and no tool_use — treat as empty response
        conv = Conversation.add_response(conv, response)
        {:ok, "", conv, tool_log, iteration + 1}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp agentic_loop(_conv, _tools, _modules, _config, _tool_log, _iteration, _max) do
    {:error, :max_iterations_reached}
  end
end
