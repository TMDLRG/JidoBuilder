defmodule JidoBuilderRuntime.Actions.Echo do
  @moduledoc "Echo payload back to caller."
  use Jido.Action,
    name: "echo",
    description: "Returns the inbound message payload",
    schema: [message: [type: :any, required: false]]

  @spec run(map(), map()) :: {:ok, map()}
  def run(params, _context) do
    {:ok, %{echo: Map.get(params, :message) || Map.get(params, "message") || params}}
  end
end
