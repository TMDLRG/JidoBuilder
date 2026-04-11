defmodule JidoBuilderRuntime.Debug do
  @moduledoc """
  Workspace-aware debug helpers.
  """

  alias JidoBuilderCore.Observability
  alias JidoBuilderRuntime.{Context, Error}

  @type result(t) :: {:ok, t} | {:error, Error.t()}

  @spec debug(map()) :: result(Jido.Debug.level())
  def debug(context) do
    with {:ok, ctx} <- Context.validate(context) do
      {:ok, Jido.Debug.level(ctx.jido_instance)}
    end
  end

  @spec recent(map(), pid(), non_neg_integer()) :: result([map()])
  def recent(context, pid, limit \\ 50) when is_pid(pid) and is_integer(limit) and limit > 0 do
    with {:ok, ctx} <- Context.validate(context),
         {:ok, events} <- Jido.AgentServer.recent_events(pid, limit: limit),
         :ok <- log(ctx, "debug.recent", %{pid: inspect(pid), count: length(events)}) do
      {:ok, events}
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error,
         Error.new(:recent_failed, "unable to fetch debug events", %{reason: inspect(reason)})}
    end
  end

  @spec set_debug(map(), pid(), boolean()) :: :ok | {:error, Error.t()}
  def set_debug(context, pid, enabled) when is_pid(pid) and is_boolean(enabled) do
    with {:ok, ctx} <- Context.validate(context),
         :ok <- Jido.AgentServer.set_debug(pid, enabled),
         :ok <- log(ctx, "debug.set", %{pid: inspect(pid), enabled: enabled}) do
      :ok
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error,
         Error.new(:set_debug_failed, "unable to change debug mode", %{reason: inspect(reason)})}
    end
  end

  defp log(ctx, type, payload) do
    attrs =
      Context.base_log_attrs(ctx, %{
        directive_type: type,
        status: "ok",
        payload: payload
      })

    case Observability.log_directive(attrs, ctx.actor) do
      {:ok, _row} ->
        :ok

      {:error, reason} ->
        {:error,
         Error.new(:log_failed, "failed to persist debug audit log", %{reason: inspect(reason)})}
    end
  end
end
