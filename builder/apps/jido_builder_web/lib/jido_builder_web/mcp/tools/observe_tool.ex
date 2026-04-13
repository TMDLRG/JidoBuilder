defmodule JidoBuilderWeb.MCP.Tools.ObserveTool do
  @moduledoc "MCP tool: jido_observe — query observability data."

  alias JidoBuilderCore.Observability

  def call(%{"action" => "signals"} = args, %{workspace_id: ws_id}) do
    limit = args["limit"] || 50
    signals = Observability.list_recent_signals(ws_id, limit: limit)
    {:ok, Enum.map(signals, fn s -> %{id: s.id, signal_type: s.signal_type, direction: s.direction, correlation_id: s.correlation_id} end)}
  end

  def call(%{"action" => "errors"} = args, %{workspace_id: ws_id}) do
    limit = args["limit"] || 50
    errors = Observability.list_recent_errors(ws_id, limit: limit)
    {:ok, Enum.map(errors, fn e -> %{id: e.id, directive_type: e.directive_type, status: e.status} end)}
  end

  def call(%{"action" => "correlation", "correlation_id" => cid}, %{workspace_id: ws_id}) do
    result = Observability.get_by_correlation_id(ws_id, cid)
    {:ok, %{signal_logs: length(result.signal_logs), directive_logs: length(result.directive_logs)}}
  end

  def call(%{"action" => "dashboard"}, %{workspace_id: ws_id}) do
    signals = Observability.list_recent_signals(ws_id, limit: 1000)
    errors = Observability.list_recent_errors(ws_id, limit: 1000)
    {:ok, %{total_signals: length(signals), total_errors: length(errors)}}
  end

  def call(_, _), do: {:ok, "jido_observe — Actions: signals, errors, correlation, dashboard, help"}
end
