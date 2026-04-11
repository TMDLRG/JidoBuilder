defmodule JidoBuilderRuntime.Discovery do
  @moduledoc """
  Thin wrapper around `Jido.Discovery` with runtime context validation.
  """

  alias JidoBuilderRuntime.{Context, Error}

  @type result(t) :: {:ok, t} | {:error, Error.t()}

  @spec list_agents(map(), keyword()) :: result(list())
  def list_agents(context, opts \\ []) do
    with {:ok, _ctx} <- Context.validate(context) do
      {:ok, Jido.Discovery.list_agents(opts)}
    end
  end

  @spec list_actions(map(), keyword()) :: result(list())
  def list_actions(context, opts \\ []) do
    with {:ok, _ctx} <- Context.validate(context) do
      {:ok, Jido.Discovery.list_actions(opts)}
    end
  end

  @spec list_sensors(map(), keyword()) :: result(list())
  def list_sensors(context, opts \\ []) do
    with {:ok, _ctx} <- Context.validate(context) do
      {:ok, Jido.Discovery.list_sensors(opts)}
    end
  end

  @spec list_plugins(map(), keyword()) :: result(list())
  def list_plugins(context, opts \\ []) do
    with {:ok, _ctx} <- Context.validate(context) do
      {:ok, Jido.Discovery.list_plugins(opts)}
    end
  end

  @spec refresh(map()) :: :ok | {:error, Error.t()}
  def refresh(context) do
    with {:ok, _ctx} <- Context.validate(context),
         :ok <- Jido.Discovery.refresh() do
      :ok
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error,
         Error.new(:discovery_failed, "unable to refresh discovery", %{reason: inspect(reason)})}
    end
  end
end
