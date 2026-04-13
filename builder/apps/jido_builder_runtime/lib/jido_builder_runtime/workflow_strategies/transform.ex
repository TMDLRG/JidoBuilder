defmodule JidoBuilderRuntime.WorkflowStrategies.Transform do
  @moduledoc "Applies map/filter/merge transformation to workflow state."

  @spec execute(map(), map()) :: {:ok, map()} | {:error, term()}
  def execute(step, state) do
    config = step.config || %{}
    operation = config["operation"] || Map.get(config, :operation, "merge")
    value = config["value"] || Map.get(config, :value, %{})

    case operation do
      "merge" ->
        {:ok, atomize_keys(value)}

      "filter" ->
        keys = config["keys"] || Map.get(config, :keys, [])
        {:ok, Map.take(state, keys)}

      _ ->
        {:ok, atomize_keys(value)}
    end
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_atom(k), v}
      {k, v} -> {k, v}
    end)
  end

  defp atomize_keys(value), do: value
end
