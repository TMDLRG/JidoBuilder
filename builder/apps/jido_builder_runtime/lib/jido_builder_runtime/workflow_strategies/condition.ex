defmodule JidoBuilderRuntime.WorkflowStrategies.Condition do
  @moduledoc "Evaluates expression against state; false skips downstream."

  @spec execute(map(), map()) :: {:ok, map()}
  def execute(step, state) do
    config = step.config || %{}
    field = config["field"] || Map.get(config, :field)
    expected = config["expected"] || Map.get(config, :expected)

    met =
      if field do
        Map.get(state, field) == expected ||
          Map.get(state, to_string(field)) == expected
      else
        false
      end

    {:ok, %{condition_met: met}}
  end
end
