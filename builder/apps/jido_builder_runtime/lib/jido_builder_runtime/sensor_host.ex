defmodule JidoBuilderRuntime.SensorHost do
  @moduledoc """
  Lightweight host for managing dynamic sensor mounts.
  """

  use GenServer

  alias JidoBuilderRuntime.{DynamicSensor, Error}

  @type state :: %{template_id: pos_integer(), mounts: [{module(), map()}]}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))
  end

  @impl true
  def init(opts) do
    template_id = Keyword.fetch!(opts, :template_id)

    case DynamicSensor.mounts_for_template(template_id) do
      {:ok, mounts} -> {:ok, %{template_id: template_id, mounts: mounts}}
      {:error, %Error{} = error} -> {:stop, error}
    end
  end

  @impl true
  def handle_call(:mounts, _from, state), do: {:reply, {:ok, state.mounts}, state}
end
