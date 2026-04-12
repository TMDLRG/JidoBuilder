defmodule JidoBuilderWeb.TracesLive do
  @moduledoc "Phase Final A.7 — Traces viewer with filters and details."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Observability

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)
    signals = Observability.list_recent_signals(workspace_id, limit: 50)

    {:ok,
     assign(socket,
       page_title: "Traces",
       workspace_id: workspace_id,
       all_signals: signals,
       signals: signals,
       selected: nil,
       filter: %{"signal_type" => ""}
     )}
  end

  @impl true
  def handle_event("filter", %{"filter" => %{"signal_type" => signal_type}}, socket) do
    value = String.downcase(String.trim(signal_type || ""))

    signals =
      Enum.filter(socket.assigns.all_signals, fn row ->
        value == "" || String.contains?(String.downcase(row.signal_type || ""), value)
      end)

    {:noreply, assign(socket, signals: signals, filter: %{"signal_type" => signal_type}, selected: nil)}
  end

  def handle_event("select", %{"id" => id}, socket) do
    selected = Enum.find(socket.assigns.signals, &(to_string(&1.id) == id))
    {:noreply, assign(socket, selected: selected)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <form id="trace-filter-form" phx-change="filter" class="my-3 max-w-md">
      <input type="text" name="filter[signal_type]" value={@filter["signal_type"]} placeholder="Filter by signal type" class="border rounded px-2 py-1 w-full text-sm" />
    </form>

    <ul id="trace-signals-list" class="space-y-1 text-sm">
      <li :for={s <- @signals} class="font-mono text-xs border-b pb-1">
        <button type="button" phx-click="select" phx-value-id={s.id} class="w-full text-left">
          <span><%= s.signal_type %></span>
          <span class="ml-2 text-zinc-500"><%= s.status %></span>
        </button>
      </li>
    </ul>
    <p :if={@signals == []} class="text-sm text-zinc-500">No trace signals yet.</p>

    <pre :if={@selected} id="trace-detail" class="mt-6 rounded border bg-zinc-50 p-3 text-xs font-mono whitespace-pre-wrap"><%= inspect(@selected, pretty: true) %></pre>
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
