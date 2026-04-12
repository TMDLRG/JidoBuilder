defmodule JidoBuilderRuntime.Actions.LogMessage do
  @moduledoc "Append a message entry to an agent log."
  use Jido.Action,
    name: "log_message",
    description: "Appends message payload to log",
    schema: [message: [type: :any, required: true], log: [type: {:list, :map}, default: []]]

  @spec run(map(), map()) :: {:ok, map()}
  def run(params, _context) do
    message = Map.get(params, :message, Map.get(params, "message"))
    log = Map.get(params, :log, Map.get(params, "log", []))

    entry = %{message: message, logged_at: DateTime.utc_now()}
    {:ok, %{log: log ++ [entry], entry: entry}}
  end
end
