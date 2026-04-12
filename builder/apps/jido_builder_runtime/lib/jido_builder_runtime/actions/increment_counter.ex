defmodule JidoBuilderRuntime.Actions.IncrementCounter do
  @moduledoc "Increment an agent counter state field."
  use Jido.Action,
    name: "increment_counter",
    description: "Increments counter by amount",
    schema: [counter: [type: :integer, default: 0], amount: [type: :integer, default: 1]]

  @spec run(map(), map()) :: {:ok, map()}
  def run(params, _context) do
    counter = Map.get(params, :counter, Map.get(params, "counter", 0))
    amount = Map.get(params, :amount, Map.get(params, "amount", 1))
    {:ok, %{counter: counter + amount}}
  end
end
