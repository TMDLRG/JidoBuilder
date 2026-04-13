defmodule JidoBuilderRuntime.LLM.ToolBridge do
  @moduledoc """
  Bridge between Jido Actions and LLM tool schemas.

  Converts Action modules to LLM-compatible tool definitions and
  routes LLM tool_use responses back to Action execution.
  """

  alias Jido.Action.Tool, as: ActionTool
  alias JidoBuilderRuntime.LLM.Client.ToolUse

  @doc """
  Convert a list of Action modules to LLM tool schemas.

  Uses `Action.Tool.to_tool/1` to generate tool definitions with
  name, description, and JSON Schema parameters.
  """
  @spec actions_to_tools([module()]) :: [map()]
  def actions_to_tools(action_modules) when is_list(action_modules) do
    Enum.map(action_modules, fn mod ->
      tool = ActionTool.to_tool(mod)
      %{
        name: tool.name,
        description: tool.description,
        parameters_schema: tool.parameters_schema
      }
    end)
  end

  @doc """
  Resolve a tool_use response to an Action module.

  Looks up the Action module by matching the tool name against
  the action's `name/0` callback.
  """
  @spec resolve_action(ToolUse.t(), [module()]) :: {:ok, module()} | {:error, String.t()}
  def resolve_action(%ToolUse{name: name}, action_modules) do
    case Enum.find(action_modules, fn mod -> mod.name() == name end) do
      nil -> {:error, "No action found for tool '#{name}'"}
      mod -> {:ok, mod}
    end
  end

  @doc """
  Execute a tool_use response against the matching Action.

  Resolves the action, converts parameters using the action's schema,
  and executes via `Jido.Exec.run/3`.
  """
  @spec execute_tool_use(ToolUse.t(), [module()], map()) ::
          {:ok, term()} | {:error, term()}
  def execute_tool_use(%ToolUse{} = tool_use, action_modules, context \\ %{}) do
    with {:ok, action_mod} <- resolve_action(tool_use, action_modules) do
      params = ActionTool.convert_params_using_schema(
        tool_use.arguments,
        action_mod.schema()
      )

      Jido.Exec.run(action_mod, params, context)
    end
  end

  @doc """
  Format a tool execution result for LLM consumption.

  Returns a message map suitable for appending to the conversation
  as a tool_result.
  """
  @spec format_tool_result(String.t(), term()) :: map()
  def format_tool_result(tool_use_id, {:ok, result}) do
    %{
      role: "tool",
      tool_use_id: tool_use_id,
      content: encode_result(result)
    }
  end

  def format_tool_result(tool_use_id, {:error, reason}) do
    %{
      role: "tool",
      tool_use_id: tool_use_id,
      content: Jason.encode!(%{error: inspect(reason)}),
      is_error: true
    }
  end

  defp encode_result(result) when is_map(result), do: Jason.encode!(result)
  defp encode_result(result) when is_binary(result), do: result
  defp encode_result(result), do: inspect(result)
end
