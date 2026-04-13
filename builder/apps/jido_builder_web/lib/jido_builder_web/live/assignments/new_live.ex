defmodule JidoBuilderWeb.Assignments.NewLive do
  use JidoBuilderWeb, :live_view

  import JidoBuilderWeb.Components.ExecutionResult

  alias JidoBuilderCore.{Observability, Templates}
  alias JidoBuilderRuntime.{EventBus, Hiring, Roster, Signals}

  @history_limit 25

  @impl true
  def mount(params, _session, socket) do
    workspace_id = workspace_id_from_params(params)
    history = Observability.list_recent_signals(workspace_id, limit: @history_limit)

    {:ok,
     assign(socket,
       page_title: "Dispatch Signal",
       workspace_id: workspace_id,
       agents: Roster.list(workspace_id),
       selected_agent: nil,
       selected_agent_routes: [],
       signal_type: "ping",
       payload: Jason.encode!(%{"message" => "hello"}, pretty: true),
       result: nil,
       error: nil,
       dispatch_mode: :sync,
       dispatch_history: history,
       expanded_row: nil,
       timeline_events: []
     )}
  end

  defp workspace_id_from_params(%{"workspace_id" => id}) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end

  defp workspace_id_from_params(_), do: 1

  @impl true
  def handle_event("pick_agent", %{"id" => id}, socket) do
    routes = agent_template_routes(id, socket.assigns.agents)

    {:noreply, assign(socket, selected_agent: id, selected_agent_routes: routes)}
  end

  @impl true
  def handle_event("update_dispatch_form", %{"dispatch" => params}, socket) do
    {:noreply,
     assign(socket,
       signal_type: Map.get(params, "signal_type", socket.assigns.signal_type),
       payload: Map.get(params, "payload", socket.assigns.payload)
     )}
  end

  @impl true
  def handle_event("toggle_mode", _params, socket) do
    new_mode = if socket.assigns.dispatch_mode == :sync, do: :async, else: :sync
    {:noreply, assign(socket, dispatch_mode: new_mode)}
  end

  @impl true
  def handle_event("expand_row", %{"id" => id}, socket) do
    current = socket.assigns.expanded_row
    new_expanded = if current == id, do: nil, else: id
    {:noreply, assign(socket, expanded_row: new_expanded)}
  end

  @impl true
  def handle_event("dispatch", %{"dispatch" => %{"signal_type" => sig_type} = params}, socket) do
    user = socket.assigns.current_user
    target = socket.assigns.selected_agent || Map.get(params, "target_agent")
    mode = socket.assigns.dispatch_mode
    do_dispatch(socket, user, target, sig_type, Map.get(params, "payload", "{}"), mode)
  end

  @impl true
  def handle_info({:jido_event, event}, socket) do
    timeline_event = %{
      id: System.unique_integer([:positive]),
      kind: event[:kind] || "unknown",
      status: event[:status] || "unknown",
      timestamp: event[:measured_at] || DateTime.utc_now(),
      duration_ms: format_native_duration(event[:duration_native])
    }

    events = [timeline_event | socket.assigns.timeline_events] |> Enum.take(50)
    {:noreply, assign(socket, timeline_events: events)}
  end

  defp agent_template_routes(agent_name, agents) do
    case Enum.find(agents, fn a -> a.name == agent_name end) do
      %{template_id: tid} when is_integer(tid) ->
        Templates.list_routes(tid) |> Enum.map(& &1.signal)

      _ ->
        []
    end
  end

  defp do_dispatch(socket, _user, nil, _sig_type, _payload_str, _mode) do
    {:noreply, assign(socket, error: "Select an agent first.", result: nil)}
  end

  defp do_dispatch(socket, user, target, sig_type, payload_str, mode) do
    payload =
      case Jason.decode(payload_str) do
        {:ok, map} when is_map(map) -> map
        _ -> %{}
      end

    context = %{workspace_id: socket.assigns.workspace_id, actor: user.email}

    with {:ok, server} <- Hiring.whereis(context, target),
         {:ok, signal} <- Signals.new(context, sig_type, payload) do
      case mode do
        :sync -> dispatch_sync(socket, context, server, signal, target)
        :async -> dispatch_async(socket, context, server, signal, target)
      end
    else
      {:error, reason} ->
        {:noreply, assign(socket, error: inspect(reason), result: nil)}
    end
  end

  defp dispatch_sync(socket, context, server, signal, target) do
    case Signals.timed_call(context, server, signal) do
      {:ok, agent_state, elapsed_ms} ->
        result = %{
          status: :success,
          elapsed_ms: elapsed_ms,
          agent_state: agent_state,
          signal_type: signal.type,
          target_agent: target,
          correlation_id: signal.extensions[:correlation_id]
        }

        {:noreply, socket |> assign(result: result, error: nil) |> refresh_history()}

      {:error, error, elapsed_ms} ->
        result = %{
          status: :error,
          elapsed_ms: elapsed_ms,
          error: inspect(error),
          signal_type: signal.type,
          target_agent: target,
          correlation_id: signal.extensions[:correlation_id]
        }

        {:noreply, socket |> assign(result: result, error: nil) |> refresh_history()}
    end
  end

  defp dispatch_async(socket, context, server, signal, target) do
    correlation_id = signal.extensions[:correlation_id]

    # Subscribe to correlation topic for real-time events
    if correlation_id do
      topic = EventBus.correlation_topic(socket.assigns.workspace_id, correlation_id)
      Phoenix.PubSub.subscribe(JidoBuilder.PubSub, topic)
    end

    case Signals.cast(context, server, signal) do
      :ok ->
        result = %{
          status: :pending,
          signal_type: signal.type,
          target_agent: target,
          correlation_id: correlation_id
        }

        {:noreply, socket |> assign(result: result, error: nil, timeline_events: []) |> refresh_history()}

      {:error, reason} ->
        {:noreply, assign(socket, error: inspect(reason), result: nil)}
    end
  end

  @common_signals ~w(ping command query transform health_check status sync reset)

  defp signal_type_options(agent_routes) when is_list(agent_routes) and agent_routes != [] do
    (agent_routes ++ @common_signals) |> Enum.uniq()
  end

  defp signal_type_options(_), do: @common_signals

  defp refresh_history(socket) do
    history = Observability.list_recent_signals(socket.assigns.workspace_id, limit: @history_limit)
    assign(socket, dispatch_history: history)
  end

  defp format_timestamp(%NaiveDateTime{} = ts), do: Calendar.strftime(ts, "%H:%M:%S")
  defp format_timestamp(_), do: "—"

  defp format_native_duration(nil), do: nil
  defp format_native_duration(native) when is_integer(native) do
    System.convert_time_unit(native, :native, :millisecond)
  end
  defp format_native_duration(_), do: nil

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Dispatch Signal</.page_header>
    <section class="grid md:grid-cols-3 gap-4">
      <.card class="md:col-span-2">
        <:header>Select Agent</:header>
        <div class="grid md:grid-cols-2 gap-2">
          <button :for={agent <- @agents} phx-click="pick_agent" phx-value-id={agent.name} class={["ui-card-body border rounded text-left", if(@selected_agent == agent.name, do: "border-emerald-500", else: "border-zinc-200")]}>{agent.name}</button>
        </div>
        <form id="dispatch-form" phx-submit="dispatch" phx-change="update_dispatch_form" class="mt-4 space-y-2">
          <label class="ui-label block text-sm">
            <span class="block text-xs font-medium text-zinc-600 mb-1">Signal type</span>
            <select name="dispatch[signal_type]" class="ui-input">
              <%= for sig <- signal_type_options(@selected_agent_routes) do %>
                <option value={sig} selected={sig == @signal_type}>{sig}</option>
              <% end %>
            </select>
          </label>
          <label class="ui-label block text-sm">
            <span class="block text-xs font-medium text-zinc-600 mb-1">Payload JSON</span>
            <textarea name="dispatch[payload]" class="ui-input font-mono" rows="6">{@payload}</textarea>
          </label>
          <div class="flex items-center gap-3">
            <.button>Dispatch</.button>
            <button type="button" phx-click="toggle_mode" class="text-xs text-zinc-500 hover:text-zinc-700">
              Mode: <span class="font-semibold">{if @dispatch_mode == :sync, do: "Sync", else: "Async"}</span>
            </button>
          </div>
        </form>
      </.card>
      <.card>
        <:header>Result</:header>
        <.execution_result :if={@result} result={@result} />
        <div :if={@error} class="rounded bg-red-50 border border-red-200 p-3 text-sm text-red-700">{@error}</div>
        <.empty_state :if={is_nil(@result) and is_nil(@error)} title="No result yet" description="Dispatch a signal to view output." icon="command_line" />

        <%!-- Real-time execution timeline for async dispatches --%>
        <div :if={@timeline_events != []} id="execution-timeline" class="mt-4 border-t pt-3">
          <h4 class="text-xs font-semibold text-zinc-600 mb-2">Execution Timeline</h4>
          <div class="space-y-1">
            <div :for={ev <- @timeline_events} class="flex items-center gap-2 text-xs">
              <span class={[
                "inline-block w-1.5 h-1.5 rounded-full",
                timeline_status_color(ev.status)
              ]}></span>
              <span class="text-zinc-500">{format_event_time(ev.timestamp)}</span>
              <span class="font-mono">{ev.kind}</span>
              <span class={["font-medium", timeline_text_color(ev.status)]}>{ev.status}</span>
              <span :if={ev.duration_ms} class="text-zinc-400">{ev.duration_ms} ms</span>
            </div>
          </div>
        </div>
      </.card>
    </section>

    <section id="dispatch-history" class="mt-6">
      <.card>
        <:header>Dispatch History</:header>
        <div :if={@dispatch_history == []} class="text-sm text-zinc-400 italic py-4 text-center">
          No dispatches yet.
        </div>
        <table :if={@dispatch_history != []} class="w-full text-sm">
          <thead>
            <tr class="text-left text-xs text-zinc-500 border-b">
              <th class="py-2 px-2">Timestamp</th>
              <th class="py-2 px-2">Signal Type</th>
              <th class="py-2 px-2">Direction</th>
              <th class="py-2 px-2">Correlation ID</th>
            </tr>
          </thead>
          <tbody>
            <tr
              :for={log <- @dispatch_history}
              phx-click="expand_row"
              phx-value-id={to_string(log.id)}
              class="border-b border-zinc-100 hover:bg-zinc-50 cursor-pointer"
            >
              <td class="py-2 px-2 text-xs text-zinc-500">{format_timestamp(log.inserted_at)}</td>
              <td class="py-2 px-2 font-mono text-xs">{log.signal_type}</td>
              <td class="py-2 px-2 text-xs">{log.direction}</td>
              <td class="py-2 px-2 text-xs text-zinc-400 truncate max-w-[120px]">{log.correlation_id || "—"}</td>
            </tr>
          </tbody>
        </table>
      </.card>
    </section>
    """
  end

  defp timeline_status_color("stop"), do: "bg-green-500"
  defp timeline_status_color("start"), do: "bg-blue-500"
  defp timeline_status_color("exception"), do: "bg-red-500"
  defp timeline_status_color(_), do: "bg-zinc-400"

  defp timeline_text_color("stop"), do: "text-green-700"
  defp timeline_text_color("start"), do: "text-blue-700"
  defp timeline_text_color("exception"), do: "text-red-700"
  defp timeline_text_color(_), do: "text-zinc-600"

  defp format_event_time(%DateTime{} = dt), do: Calendar.strftime(dt, "%H:%M:%S.%f") |> String.slice(0..11)
  defp format_event_time(_), do: "—"
end
