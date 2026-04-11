defmodule JidoBuilderCodegen.Templates do
  alias JidoBuilderCodegen.Templates.{Action, Agent, Plugin, Sensor, Strategy}

  @renderers %{
    action: Action,
    agent: Agent,
    plugin: Plugin,
    sensor: Sensor,
    strategy: Strategy
  }

  @spec render(map()) :: {:ok, String.t()} | {:error, term()}
  def render(%{type: type} = block) do
    case Map.fetch(@renderers, type) do
      {:ok, mod} -> {:ok, mod.render(block)}
      :error -> {:error, {:unsupported_block_type, type}}
    end
  end
end
