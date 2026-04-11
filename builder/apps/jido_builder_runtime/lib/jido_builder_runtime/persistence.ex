defmodule JidoBuilderRuntime.Persistence do
  @moduledoc """
  Persistence wrappers around Jido hibernate/thaw with snapshot rows.
  """

  alias JidoBuilderCore.Agents
  alias JidoBuilderRuntime.{Context, Error}

  @type result(t) :: {:ok, t} | {:error, Error.t()}

  @spec hibernate(map(), Jido.Agent.t()) :: :ok | {:error, Error.t()}
  def hibernate(context, agent) do
    with {:ok, ctx} <- Context.validate(context),
         :ok <- Jido.hibernate(ctx.jido_instance, agent, Context.partition_opts(ctx)),
         :ok <- snapshot(ctx, %{hibernate: true}) do
      :ok
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error, Error.new(:hibernate_failed, "hibernate failed", %{reason: inspect(reason)})}
    end
  end

  @spec thaw(map(), module(), term()) :: result(Jido.Agent.t())
  def thaw(context, agent_module, key) do
    with {:ok, ctx} <- Context.validate(context),
         {:ok, agent} <-
           Jido.thaw(ctx.jido_instance, agent_module, key, Context.partition_opts(ctx)),
         :ok <- snapshot(ctx, %{thaw: true, key: inspect(key)}) do
      {:ok, agent}
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error, Error.new(:thaw_failed, "thaw failed", %{reason: inspect(reason)})}
    end
  end

  defp snapshot(ctx, metadata) do
    agent_instance_id = Map.get(ctx, :agent_instance_id)

    if is_integer(agent_instance_id) do
      attrs = %{
        workspace_id: ctx.workspace_id,
        agent_instance_id: agent_instance_id,
        captured_at: DateTime.utc_now(),
        metadata: metadata,
        hibernate_metadata: if(metadata[:hibernate], do: %{at: DateTime.utc_now()}, else: %{}),
        thaw_metadata: if(metadata[:thaw], do: %{at: DateTime.utc_now()}, else: %{})
      }

      case Agents.create_snapshot(attrs, ctx.actor) do
        {:ok, _row} ->
          :ok

        {:error, reason} ->
          {:error,
           Error.new(:snapshot_failed, "snapshot insert failed", %{reason: inspect(reason)})}
      end
    else
      :ok
    end
  end
end
