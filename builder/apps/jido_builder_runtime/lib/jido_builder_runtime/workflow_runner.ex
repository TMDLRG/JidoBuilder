defmodule JidoBuilderRuntime.WorkflowRunner do
  @moduledoc """
  Orchestration helpers for workflow lifecycle actions.
  """

  alias JidoBuilderCore.{Observability, Workflows}
  alias JidoBuilderRuntime.{Context, Error, Hiring, Signals}

  @type result(t) :: {:ok, t} | {:error, Error.t()}

  @spec start_and_signal(
          map(),
          module() | struct(),
          Jido.Signal.t() | {String.t(), map(), keyword()}
        ) ::
          result(%{pid: pid(), agent: struct()})
  def start_and_signal(context, agent, signal_or_tuple) do
    with {:ok, ctx} <- Context.validate(context),
         {:ok, pid} <- Hiring.start(ctx, agent),
         {:ok, signal} <- normalize_signal(ctx, signal_or_tuple),
         {:ok, updated_agent} <- Signals.call(ctx, pid, signal),
         :ok <- log(ctx, "workflow.start_and_signal", %{pid: inspect(pid), signal: signal.type}) do
      {:ok, %{pid: pid, agent: updated_agent}}
    end
  end

  @spec await(map(), Jido.AgentServer.server(), timeout()) :: result(map())
  def await(context, server, timeout \\ 10_000) do
    with {:ok, ctx} <- Context.validate(context),
         {:ok, result} <- Jido.await(server, timeout),
         :ok <- log(ctx, "workflow.await", %{server: inspect(server), status: inspect(result)}) do
      {:ok, result}
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error, Error.new(:await_failed, "await failed", %{reason: inspect(reason)})}
    end
  end

  @spec complete_workflow(map(), JidoBuilderCore.Workflows.Workflow.t(), String.t(), map()) ::
          result(JidoBuilderCore.Workflows.Workflow.t())
  def complete_workflow(context, workflow, status, metadata \\ %{}) do
    with {:ok, ctx} <- Context.validate(context),
         {:ok, updated} <-
           Workflows.update_workflow(workflow, %{status: status, metadata: metadata}, ctx.actor),
         :ok <- log(ctx, "workflow.complete", %{workflow_id: workflow.id, status: status}) do
      {:ok, updated}
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error,
         Error.new(:workflow_update_failed, "failed to update workflow", %{
           reason: inspect(reason)
         })}
    end
  end

  defp normalize_signal(_ctx, %Jido.Signal{} = signal), do: {:ok, signal}

  defp normalize_signal(ctx, {type, payload, opts}) do
    Signals.new(ctx, type, payload, opts)
  end

  defp log(ctx, directive_type, payload) do
    attrs =
      Context.base_log_attrs(ctx, %{
        directive_type: directive_type,
        status: "ok",
        payload: payload
      })

    case Observability.log_directive(attrs, ctx.actor) do
      {:ok, _row} ->
        :ok

      {:error, reason} ->
        {:error,
         Error.new(:log_failed, "failed to persist workflow runtime log", %{
           reason: inspect(reason)
         })}
    end
  end
end
