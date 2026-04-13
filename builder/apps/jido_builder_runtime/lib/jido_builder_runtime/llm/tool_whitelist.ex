defmodule JidoBuilderRuntime.LLM.ToolWhitelist do
  @moduledoc """
  Resolves a list of action slugs into their corresponding Action modules.

  Used to enforce the tool_whitelist field from TemplateLlmConfig —
  only whitelisted actions are exposed to the LLM as callable tools.
  """

  alias JidoBuilderRuntime.ActionRegistry

  @doc """
  Resolve a list of slug strings to Action modules.

  Returns only modules for slugs that exist in the ActionRegistry.
  Returns `[]` for empty or nil input.

  ## Examples

      iex> ToolWhitelist.resolve(["echo", "web_fetch"])
      [JidoBuilderRuntime.Actions.Echo, JidoBuilderRuntime.Actions.Tools.WebFetch]

      iex> ToolWhitelist.resolve([])
      []
  """
  @spec resolve([String.t()] | nil) :: [module()]
  def resolve(slugs) when is_list(slugs) and slugs != [] do
    slugs
    |> Enum.map(&ActionRegistry.get/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(& &1.module)
  end

  def resolve(_), do: []
end
