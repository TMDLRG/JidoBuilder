defmodule JidoBuilderRuntime.Signals do
  @moduledoc """
  Signal helpers for composing and dispatching runtime signals.
  """

  alias JidoBuilderCore.Observability
  alias JidoBuilderRuntime.{Context, Error}

  @type result(t) :: {:ok, t} | {:error, Error.t()}

  @spec new(map(), String.t(), map(), keyword()) :: result(Jido.Signal.t())
  def new(context, type, data \\ %{}, opts \\ []) do
    with {:ok, _ctx} <- Context.validate(context) do
      {:ok, Jido.Signal.new!(type, data, opts)}
    rescue
      error ->
        {:error,
         Error.new(:invalid_signal, "unable to create signal", %{error: Exception.message(error)})}
    end
  end

  @spec call(map(), Jido.AgentServer.server(), Jido.Signal.t(), timeout()) :: result(struct())
  def call(context, server, signal, timeout \\ 5_000) do
    dispatch(context, :inbound, "signal.call", fn ->
      Jido.AgentServer.call(server, signal, timeout)
    end)
  end

  @spec cast(map(), Jido.AgentServer.server(), Jido.Signal.t()) :: :ok | {:error, Error.t()}
  def cast(context, server, signal) do
    dispatch(context, :inbound, "signal.cast", fn -> Jido.AgentServer.cast(server, signal) end)
    |> case do
      {:ok, :ok} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  defp dispatch(context, direction, signal_type, fun) do
    with {:ok, ctx} <- Context.validate(context),
         {:ok, result} <- normalize(fun.()),
         :ok <- log_signal(ctx, direction, signal_type) do
      {:ok, result}
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error,
         Error.new(:dispatch_failed, "signal dispatch failed", %{reason: inspect(reason)})}
    end
  end

  defp normalize({:ok, value}), do: {:ok, value}
  defp normalize(:ok), do: {:ok, :ok}
  defp normalize({:error, reason}), do: {:error, reason}

  defp log_signal(ctx, direction, signal_type) do
    attrs =
      Context.base_log_attrs(ctx, %{
        direction: to_string(direction),
        signal_type: signal_type,
        payload: %{}
      })

    case Observability.log_signal(attrs, ctx.actor) do
      {:ok, _row} ->
        :ok

      {:error, reason} ->
        {:error, Error.new(:log_failed, "failed to log signal", %{reason: inspect(reason)})}
    end
  end
end
