defmodule JidoBuilderRuntime.Context do
  @moduledoc false

  alias JidoBuilderRuntime.Error

  @type t :: %{
          required(:workspace_id) => pos_integer(),
          required(:actor) => String.t(),
          optional(:partition) => term(),
          optional(:jido_instance) => atom(),
          optional(:agent_instance_id) => pos_integer(),
          optional(:workflow_id) => pos_integer()
        }

  @spec validate(map()) :: {:ok, t()} | {:error, Error.t()}
  def validate(%{} = ctx) do
    workspace_id = Map.get(ctx, :workspace_id)
    actor = Map.get(ctx, :actor)

    cond do
      not is_integer(workspace_id) or workspace_id <= 0 ->
        {:error, Error.new(:invalid_context, "workspace_id is required", %{field: :workspace_id})}

      not is_binary(actor) or actor == "" ->
        {:error, Error.new(:invalid_context, "actor is required", %{field: :actor})}

      true ->
        {:ok, Map.put_new(ctx, :jido_instance, JidoBuilderRuntime.Jido)}
    end
  end

  @spec partition_opts(t()) :: keyword()
  def partition_opts(ctx) do
    case Map.get(ctx, :partition) do
      nil -> []
      partition -> [partition: partition]
    end
  end

  @spec base_log_attrs(t(), map()) :: map()
  def base_log_attrs(ctx, extra \\ %{}) do
    extra
    |> Map.put(:workspace_id, ctx.workspace_id)
    |> maybe_put(:agent_instance_id, Map.get(ctx, :agent_instance_id))
    |> maybe_put(:correlation_id, Map.get(ctx, :correlation_id))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
