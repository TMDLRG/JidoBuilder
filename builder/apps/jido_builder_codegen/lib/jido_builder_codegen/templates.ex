defmodule JidoBuilderCodegen.Templates do
  alias JidoBuilderCodegen.Templates.{Action, Agent, Plugin, Sensor, Strategy}

  @renderers %{
    action: Action,
    agent: Agent,
    plugin: Plugin,
    sensor: Sensor,
    strategy: Strategy
  }

  # A valid Elixir module name: one or more dot-separated segments, each
  # starting with an uppercase letter followed by alphanumerics/underscores.
  @valid_module_name ~r/^[A-Z][A-Za-z0-9_]*(\.[A-Z][A-Za-z0-9_]*)*$/

  @spec render(map()) :: {:ok, String.t()} | {:error, term()}
  def render(%{type: type, module: mod} = block) do
    with :ok <- validate_module_name(mod),
         {:ok, renderer} <- Map.fetch(@renderers, type) do
      {:ok, renderer.render(block)}
    else
      {:error, _} = err -> err
      :error -> {:error, {:unsupported_block_type, type}}
    end
  end

  def render(%{type: type}) do
    case Map.fetch(@renderers, type) do
      {:ok, _} -> {:error, :invalid_module_name}
      :error -> {:error, {:unsupported_block_type, type}}
    end
  end

  defp validate_module_name(mod) when is_binary(mod) do
    if Regex.match?(@valid_module_name, mod) do
      :ok
    else
      {:error, :invalid_module_name}
    end
  end

  defp validate_module_name(_), do: {:error, :invalid_module_name}
end
