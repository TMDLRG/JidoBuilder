defmodule JidoBuilderRuntime.Factory.AutoRoute do
  @moduledoc """
  Automatic signal route generation from action modules.

  Given a set of actions, infers signal types from action names/schemas
  and generates route definitions.
  """

  @doc """
  Generate signal routes from a list of action modules.

  Infers signal type from the action name using convention:
  - `echo` → `agent.echo`
  - `file_read` → `agent.file_read`
  - `slack_message` → `agent.slack_message`
  """
  @spec generate([module()], keyword()) :: [map()]
  def generate(action_modules, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "agent")

    Enum.map(action_modules, fn mod ->
      name = mod.name()
      signal = "#{prefix}.#{name}"
      %{
        signal: signal,
        target: name,
        action: inspect(mod),
        opts: %{}
      }
    end)
  end

  @doc """
  Generate routes from action slugs by resolving through ActionRegistry.
  """
  @spec generate_from_slugs([String.t()], keyword()) :: [map()]
  def generate_from_slugs(slugs, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "agent")
    registry = JidoBuilderRuntime.ActionRegistry.list()

    Enum.flat_map(slugs, fn slug ->
      case Enum.find(registry, fn a -> a.slug == slug end) do
        nil -> []
        action ->
          [%{
            signal: "#{prefix}.#{slug}",
            target: slug,
            action: inspect(action.module),
            opts: %{}
          }]
      end
    end)
  end
end
