defmodule JidoBuilderRuntime.Hiring do
  @moduledoc """
  Workspace-aware wrappers around Jido agent lifecycle APIs.
  """

  alias JidoBuilderCore.Observability
  alias JidoBuilderRuntime.{Context, Error}

  @type result(t) :: {:ok, t} | {:error, Error.t()}

  @spec start(map(), module() | struct(), keyword()) :: result(pid())
  def start(context, agent, opts \\ []) do
    with {:ok, ctx} <- Context.validate(context),
         {:ok, pid} <- do_start(ctx, agent, opts),
         :ok <- log(ctx, "hire.start", :success, %{pid: inspect(pid)}) do
      {:ok, pid}
    else
      {:error, %Error{} = error} -> {:error, error}
      {:error, reason} -> {:error, map_error(:start_failed, reason)}
    end
  end

  @spec stop(map(), pid() | String.t()) :: :ok | {:error, Error.t()}
  def stop(context, pid_or_id) do
    with {:ok, ctx} <- Context.validate(context),
         :ok <- do_stop(ctx, pid_or_id),
         :ok <- log(ctx, "hire.stop", :success, %{target: inspect(pid_or_id)}) do
      :ok
    else
      {:error, %Error{} = error} -> {:error, error}
      {:error, reason} -> {:error, map_error(:stop_failed, reason)}
    end
  end

  @spec list(map()) :: result([{String.t(), pid()}])
  def list(context) do
    with {:ok, ctx} <- Context.validate(context) do
      {:ok, Jido.list_agents(ctx.jido_instance, Context.partition_opts(ctx))}
    end
  end

  @spec count(map()) :: result(non_neg_integer())
  def count(context) do
    with {:ok, ctx} <- Context.validate(context) do
      {:ok, Jido.agent_count(ctx.jido_instance, Context.partition_opts(ctx))}
    end
  end

  @spec whereis(map(), String.t()) :: result(pid())
  def whereis(context, id) when is_binary(id) do
    with {:ok, ctx} <- Context.validate(context) do
      case Jido.whereis(ctx.jido_instance, id, Context.partition_opts(ctx)) do
        nil -> {:error, Error.new(:not_found, "agent not found", %{id: id})}
        pid -> {:ok, pid}
      end
    end
  end

  defp do_start(ctx, agent, opts) do
    opts = Keyword.merge(opts, Context.partition_opts(ctx))

    case Jido.start_agent(ctx.jido_instance, agent, opts) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_stop(ctx, pid_or_id) do
    case Jido.stop_agent(ctx.jido_instance, pid_or_id, Context.partition_opts(ctx)) do
      :ok ->
        :ok

      {:error, :not_found} ->
        {:error, Error.new(:not_found, "agent not found", %{target: pid_or_id})}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp log(ctx, type, status, payload) do
    attrs =
      Context.base_log_attrs(ctx, %{
        directive_type: type,
        status: to_string(status),
        payload: payload
      })

    case Observability.log_directive(attrs, ctx.actor) do
      {:ok, _row} -> :ok
      {:error, reason} -> {:error, map_error(:log_failed, reason)}
    end
  end

  defp map_error(code, reason),
    do: Error.new(code, "runtime operation failed", %{reason: inspect(reason)})
end
