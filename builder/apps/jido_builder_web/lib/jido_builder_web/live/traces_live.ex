defmodule JidoBuilderWeb.TracesLive do
  @moduledoc "Story 7.1 — Traces viewer with correlation waterfall timeline."
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
       correlation_signals: [],
       filter: %{"signal_type" => "", "correlation_id" => ""}
     )}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter_params}, socket) do
    signal_type = String.downcase(String.trim(filter_params["signal_type"] || ""))
    correlation_id = String.trim(filter_params["correlation_id"] || "")

    signals =
      socket.assigns.all_signals
      |> filter_by_signal_type(signal_type)

    correlation_signals =
      if correlation_id != "" do
        case Observability.get_by_correlation_id(socket.assigns.workspace_id, correlation_id) do
          %{signal_logs: sigs, directive_logs: dirs} ->
            (sigs ++ dirs) |> Enum.sort_by(& &1.inserted_at, DateTime)
          list when is_list(list) -> list
          _ -> []
        end
      else
        []
      end

    {:noreply,
     assign(socket,
       signals: signals,
       correlation_signals: correlation_signals,
       filter: %{"signal_type" => filter_params["signal_type"] || "", "correlation_id" => correlation_id},
       selected: nil
     )}
  end

  @impl true
  def handle_event("select", %{"id" => id}, socket) do
    selected = Enum.find(socket.assigns.signals, &(to_string(&1.id) == id))
    {:noreply, assign(socket, selected: selected)}
  end

  defp filter_by_signal_type(signals, ""), do: signals

  defp filter_by_signal_type(signals, value) do
    Enum.filter(signals, fn row ->
      String.contains?(String.downcase(row.signal_type || ""), value)
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>

    <form id="trace-filter-form" phx-change="filter" class="my-3 flex flex-col sm:flex-row gap-3">
      <div class="flex-1">
        <.input_field name="filter[signal_type]" label="Filter by signal type" value={@filter["signal_type"]} />
      </div>
      <div class="flex-1">
        <.input_field name="filter[correlation_id]" label="Filter by correlation_id" value={@filter["correlation_id"]} />
      </div>
    </form>

    <%!-- Waterfall Timeline --%>
    <div id="trace-waterfall" class="mb-6">
      <.card :if={@correlation_signals != []}>
        <:header>Correlation Timeline ({length(@correlation_signals)} events)</:header>
        <div class="space-y-1 p-2">
          <div :for={s <- @correlation_signals} class="flex items-center gap-2 text-xs font-mono">
            <span class="w-32 truncate text-zinc-500">{format_time(s.inserted_at)}</span>
            <div class="flex-1 h-5 bg-zinc-100 rounded relative">
              <div class={"h-full rounded " <> bar_color(s.log_type)} style="width: 100%"></div>
            </div>
            <span class="w-20 truncate">{s.signal_type || s.log_type}</span>
            <.badge variant={badge_variant(s.log_type)}>{s.direction || s.log_type}</.badge>
          </div>
        </div>
      </.card>
    </div>

    <.card>
      <:header>Signal Traces</:header>
      <ul id="trace-signals-list" class="space-y-1 text-sm">
        <li :for={s <- @signals} class="font-mono text-xs border-b pb-1">
          <button type="button" phx-click="select" phx-value-id={s.id} class="w-full text-left">
            <span>{s.signal_type}</span>
            <.badge variant="default">{s.direction}</.badge>
          </button>
        </li>
      </ul>
      <.empty_state :if={@signals == []} title="No traces" description="No trace signals yet." icon="eye" />
    </.card>

    <pre :if={@selected} id="trace-detail" class="mt-6 rounded border bg-zinc-50 p-3 text-xs font-mono whitespace-pre-wrap">{inspect(@selected, pretty: true)}</pre>
    """
  end

  defp format_time(nil), do: "-"
  defp format_time(dt), do: Calendar.strftime(dt, "%H:%M:%S.%f") |> String.slice(0, 12)

  defp bar_color("error"), do: "bg-red-400"
  defp bar_color("signal"), do: "bg-emerald-400"
  defp bar_color("directive"), do: "bg-blue-400"
  defp bar_color(_), do: "bg-zinc-300"

  defp badge_variant("error"), do: "danger"
  defp badge_variant("signal"), do: "success"
  defp badge_variant(_), do: "neutral"

  defp wid(%{"workspace_id" => id}) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end
  defp wid(_), do: 1
end
