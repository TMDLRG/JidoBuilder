defmodule JidoBuilderRuntime.BareAgent do
  @moduledoc """
  Runtime-safe bare agent used by roster hires.

  Includes minimal internal state and deterministic signal routing so
  operators can dispatch real work against placeholder agents.
  """

  use Jido.Agent,
    name: "builder_bare_agent",
    description: "Unconfigured placeholder agent with demo routes",
    schema: [
      counter: [type: :integer, default: 0],
      last_result: [type: :map, default: %{}],
      log: [type: {:list, :map}, default: []]
    ]

  alias JidoBuilderRuntime.Actions.{Echo, IncrementCounter, LogMessage, TransformData}

  @routes [
    {"ping", Echo},
    {"increment", IncrementCounter},
    {"transform", TransformData},
    {"log", LogMessage}
  ]
  @route_map Map.new(@routes)

  @spec signal_routes(map()) :: list()
  def signal_routes(_agent), do: @routes

  @spec route_for(String.t()) :: {:ok, module()} | {:error, map()}
  def route_for(signal_type) do
    case Map.fetch(@route_map, signal_type) do
      {:ok, mod} -> {:ok, mod}
      :error -> {:error, %{code: :no_route, signal_type: signal_type}}
    end
  end
end
