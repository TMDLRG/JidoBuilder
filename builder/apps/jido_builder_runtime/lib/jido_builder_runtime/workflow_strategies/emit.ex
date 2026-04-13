defmodule JidoBuilderRuntime.WorkflowStrategies.Emit do
  @moduledoc "Creates a signal for dispatch to a named agent."

  @spec execute(map(), map()) :: {:ok, map()}
  def execute(step, _state) do
    config = step.config || %{}
    signal_type = config["signal_type"] || Map.get(config, :signal_type, "unknown")
    payload = config["payload"] || Map.get(config, :payload, %{})

    {:ok,
     %{
       emitted_signal_type: signal_type,
       emitted_payload: payload
     }}
  end
end
