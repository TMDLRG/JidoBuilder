defmodule JidoBuilderWeb.AuditLive do
  @moduledoc "Phase 4 — Audit History: lists audit events for a workspace."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Audit

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)
    events = Audit.list_audit_events(workspace_id)

    {:ok, assign(socket, page_title: "Audit History", workspace_id: workspace_id, events: events)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <.card class="mt-4">
      <:header>Audit Events</:header>
      <.table id="audit-events" rows={@events}>
        <:col :let={ev}><span class="font-mono text-xs">{ev.action}</span> <span class="text-zinc-500">by {ev.actor}</span> <span class="text-zinc-400 text-xs">{ev.occurred_at}</span></:col>
      </.table>
      <.empty_state :if={@events == []} title="No audit events" description="No activity recorded yet." icon="eye" />
    </.card>
    """
  end

  defp wid(%{"workspace_id" => id}) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end
  defp wid(_), do: 1
end
