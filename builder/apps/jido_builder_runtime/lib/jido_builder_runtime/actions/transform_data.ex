defmodule JidoBuilderRuntime.Actions.TransformData do
  @moduledoc "Apply simple transformations to string/list data."
  use Jido.Action,
    name: "transform_data",
    description: "Transforms data via uppercase/reverse/sort",
    schema: [
      operation: [type: :string, required: true],
      data: [type: :any, required: true]
    ]

  @spec run(map(), map()) :: {:ok, map()} | {:error, map()}
  def run(params, _context) do
    operation = Map.get(params, :operation, Map.get(params, "operation"))
    data = Map.get(params, :data, Map.get(params, "data"))

    case apply_op(operation, data) do
      {:ok, result} -> {:ok, %{result: result, operation: operation}}
      {:error, _} = error -> error
    end
  end

  defp apply_op("uppercase", value) when is_binary(value), do: {:ok, String.upcase(value)}
  defp apply_op("reverse", value) when is_binary(value), do: {:ok, String.reverse(value)}
  defp apply_op("reverse", value) when is_list(value), do: {:ok, Enum.reverse(value)}
  defp apply_op("sort", value) when is_list(value), do: {:ok, Enum.sort(value)}
  defp apply_op(operation, _), do: {:error, %{code: :invalid_transform, operation: operation}}
end
