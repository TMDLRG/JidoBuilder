defmodule JidoBuilderWeb.AuditLive do
  @moduledoc "Phase 4 — Audit History: lists audit events with refresh and filter."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Audit

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)
    events = Audit.list_audit_events(workspace_id)
    actions = events |> Enum.map(& &1.action) |> Enum.uniq() |> Enum.sort()

    {:ok,
     assign(socket,
       page_title: "Audit History",
       workspace_id: workspace_id,
       events: events,
       all_events: events,
       actions: actions,
       filter_action: "all"
     )}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    events = Audit.list_audit_events(socket.assigns.workspace_id)
    actions = events |> Enum.map(& &1.action) |> Enum.uniq() |> Enum.sort()

    {:noreply,
     assign(socket,
       events: maybe_filter(events, socket.assigns.filter_action),
       all_events: events,
       actions: actions
     )}
  end

  def handle_event("filter", %{"action" => action}, socket) do
    filtered = maybe_filter(socket.assigns.all_events, action)
    {:noreply, assign(socket, events: filtered, filter_action: action)}
  end

  defp maybe_filter(events, "all"), do: events
  defp maybe_filter(events, action), do: Enum.filter(events, &(&1.action == action))

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>

    <div class="flex items-center gap-3 mt-2 mb-4">
      <button phx-click="refresh" class="px-3 py-1.5 text-sm bg-zinc-800 text-white rounded hover:bg-zinc-700 transition">
        Refresh
      </button>
      <form phx-change="filter" class="inline">
        <select name="action" class="text-sm border rounded px-2 py-1.5">
          <option value="all" selected={@filter_action == "all"}>All actions</option>
          <option :for={a <- @actions} value={a} selected={@filter_action == a}>{a}</option>
        </select>
      </form>
      <span class="text-xs text-zinc-400">{length(@events)} event(s)</span>
    </div>

    <.card>
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
