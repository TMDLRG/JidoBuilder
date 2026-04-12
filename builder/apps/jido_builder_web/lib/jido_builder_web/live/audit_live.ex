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
    <ul id="audit-events" class="space-y-2 text-sm mt-4">
      <li :for={ev <- @events} id={"audit-#{ev.id}"} class="border-b pb-2">
        <span class="font-mono text-xs"><%= ev.action %></span>
        <span class="ml-2 text-zinc-500">by <%= ev.actor %></span>
        <span class="ml-2 text-zinc-400 text-xs"><%= ev.occurred_at %></span>
      </li>
    </ul>
    <p :if={@events == []} class="text-sm text-zinc-500 mt-4">No audit events.</p>
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
