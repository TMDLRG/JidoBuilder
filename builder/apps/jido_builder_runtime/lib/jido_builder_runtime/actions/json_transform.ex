defmodule JidoBuilderRuntime.Actions.JsonTransform do
  @moduledoc "Apply JSON transformations: pick, flatten, merge, filter."
  use Jido.Action,
    name: "json_transform",
    description: "Transforms JSON data via pick/flatten/merge/filter operations",
    schema: [
      operation: [type: :string, required: true],
      data: [type: :map, required: true],
      keys: [type: {:list, :string}, default: []],
      merge_with: [type: :map, default: %{}],
      predicate_key: [type: :string, default: nil],
      predicate_value: [type: :any, default: nil]
    ]

  @spec run(map(), map()) :: {:ok, map()} | {:error, map()}
  def run(params, _context) do
    operation = get_param(params, :operation)
    data = get_param(params, :data, %{})

    case apply_transform(operation, data, params) do
      {:ok, result} -> {:ok, %{result: result, operation: operation}}
      {:error, _} = error -> error
    end
  end

  defp apply_transform("pick", data, params) when is_map(data) do
    keys = get_param(params, :keys, [])
    {:ok, Map.take(data, keys)}
  end

  defp apply_transform("flatten", data, _params) when is_map(data) do
    {:ok, flatten_map(data, "")}
  end

  defp apply_transform("merge", data, params) when is_map(data) do
    merge_with = get_param(params, :merge_with, %{})
    {:ok, deep_merge(data, merge_with)}
  end

  defp apply_transform("filter", data, params) when is_map(data) do
    key = get_param(params, :predicate_key)
    value = get_param(params, :predicate_value)

    if key do
      if Map.get(data, key) == value do
        {:ok, data}
      else
        {:ok, %{}}
      end
    else
      {:ok, data}
    end
  end

  defp apply_transform(op, _data, _params) do
    {:error, %{code: :invalid_transform, operation: op}}
  end

  defp flatten_map(map, prefix) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      full_key = if prefix == "", do: to_string(key), else: "#{prefix}.#{key}"

      case value do
        v when is_map(v) -> Map.merge(acc, flatten_map(v, full_key))
        _ -> Map.put(acc, full_key, value)
      end
    end)
  end

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _k, v1, v2 ->
      if is_map(v1) and is_map(v2), do: deep_merge(v1, v2), else: v2
    end)
  end

  defp get_param(params, key, default \\ nil) do
    Map.get(params, key) || Map.get(params, to_string(key)) || default
  end
end
