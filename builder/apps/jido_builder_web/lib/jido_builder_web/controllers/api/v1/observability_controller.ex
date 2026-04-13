defmodule JidoBuilderWeb.Api.V1.ObservabilityController do
  @moduledoc "Story 4.3 — REST API for signal history and observability queries."
  use JidoBuilderWeb, :controller

  alias JidoBuilderCore.Observability

  def signals(conn, params) do
    workspace_id = conn.assigns.workspace_id
    limit = parse_int(params["limit"], 50)

    signals = Observability.list_recent_signals(workspace_id, limit: limit)
    json(conn, %{data: Enum.map(signals, &serialize_signal/1)})
  end

  def errors(conn, params) do
    workspace_id = conn.assigns.workspace_id
    limit = parse_int(params["limit"], 50)

    errors = Observability.list_recent_errors(workspace_id, limit: limit)
    json(conn, %{data: Enum.map(errors, &serialize_directive/1)})
  end

  def correlation(conn, %{"id" => correlation_id}) do
    workspace_id = conn.assigns.workspace_id
    result = Observability.get_by_correlation_id(workspace_id, correlation_id)

    json(conn, %{
      data: %{
        signal_logs: Enum.map(result.signal_logs, &serialize_signal/1),
        directive_logs: Enum.map(result.directive_logs, &serialize_directive/1)
      }
    })
  end

  defp serialize_signal(s) do
    %{
      id: s.id,
      signal_type: s.signal_type,
      direction: s.direction,
      correlation_id: s.correlation_id,
      inserted_at: s.inserted_at
    }
  end

  defp serialize_directive(d) do
    %{
      id: d.id,
      directive_type: d.directive_type,
      status: d.status,
      correlation_id: d.correlation_id,
      inserted_at: d.inserted_at
    }
  end

  defp parse_int(nil, default), do: default
  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {n, ""} when n > 0 -> min(n, 500)
      _ -> default
    end
  end
  defp parse_int(val, _default) when is_integer(val), do: min(val, 500)
end
