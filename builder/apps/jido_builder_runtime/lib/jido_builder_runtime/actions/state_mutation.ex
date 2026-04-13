defmodule JidoBuilderRuntime.Actions.StateMutation do
  @moduledoc "Apply state mutations: set, delete, merge."
  use Jido.Action,
    name: "state_mutation",
    description: "Mutates state data via set/delete/merge operations",
    schema: [
      operation: [type: :string, required: true],
      data: [type: :map, required: true],
      changes: [type: :map, default: %{}],
      keys: [type: {:list, :string}, default: []],
      merge_with: [type: :map, default: %{}]
    ]

  @spec run(map(), map()) :: {:ok, map()} | {:error, map()}
  def run(params, _context) do
    operation = get_param(params, :operation)
    data = get_param(params, :data, %{})

    case apply_mutation(operation, data, params) do
      {:ok, result} -> {:ok, %{result: result, operation: operation}}
      {:error, _} = error -> error
    end
  end

  defp apply_mutation("set", data, params) when is_map(data) do
    changes = get_param(params, :changes, %{})
    {:ok, Map.merge(data, changes)}
  end

  defp apply_mutation("delete", data, params) when is_map(data) do
    keys = get_param(params, :keys, [])
    {:ok, Map.drop(data, keys)}
  end

  defp apply_mutation("merge", data, params) when is_map(data) do
    merge_with = get_param(params, :merge_with, %{})
    {:ok, deep_merge(data, merge_with)}
  end

  defp apply_mutation(op, _data, _params) do
    {:error, %{code: :invalid_mutation, operation: op}}
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
