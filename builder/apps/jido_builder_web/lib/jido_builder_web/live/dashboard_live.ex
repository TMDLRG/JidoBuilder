defmodule JidoBuilderWeb.DashboardLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Observability
  alias JidoBuilderRuntime.{EventBus, Roster}

  @stream_limit 200

  @impl true
  def mount(params, _session, socket) do
    workspace_id = workspace_id_from_params(params)
    topic = EventBus.workspace_activity_topic(workspace_id)

    agent_count = length(Roster.list(workspace_id))

    socket =
      socket
      |> assign(
        page_title: "Home Dashboard",
        workspace_id: workspace_id,
        workspace_topic: topic,
        agent_count: agent_count
      )
      |> stream(:activity_events, [], limit: -@stream_limit)

    if connected?(socket), do: Phoenix.PubSub.subscribe(JidoBuilder.PubSub, topic)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def terminate(_reason, socket) do
    Phoenix.PubSub.unsubscribe(JidoBuilder.PubSub, socket.assigns.workspace_topic)
    :ok
  end

  @impl true
  def handle_info({:jido_event, event}, socket) do
    row = event |> Observability.translate_event() |> Map.put(:id, event.id)
    {:noreply, stream_insert(socket, :activity_events, row, at: 0, limit: @stream_limit)}
  end

  def handle_info({:roster_hire, _instance}, socket) do
    {:noreply, assign(socket, agent_count: socket.assigns.agent_count + 1)}
  end

  def handle_info({:roster_stop, _instance}, socket) do
    {:noreply, assign(socket, agent_count: max(socket.assigns.agent_count - 1, 0))}
  end

  defp status_class(:success), do: "text-green-600"
  defp status_class(:error), do: "text-red-600"
  defp status_class(:running), do: "text-blue-600"
  defp status_class(_), do: "text-zinc-600"

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <section class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
      <div class="rounded border p-4">
        <p class="text-xs text-zinc-500 uppercase">Running Agents</p>
        <p class="text-2xl font-bold"><%= @agent_count %></p>
      </div>
    </section>

    <section class="mt-4">
      <h2 class="text-base font-semibold">Workspace Activity</h2>
      <ul id="workspace-activity" phx-update="stream" class="mt-2 space-y-1 text-sm">
        <li :for={{dom_id, row} <- @streams.activity_events} id={dom_id} class="py-1">
          <span class="font-mono"><%= row.label %></span>
          <span class={"ml-2 text-xs #{status_class(row.status)}"}>
            <%= row.status %>
          </span>
          <a :if={row.agent_link} href={row.agent_link} class="ml-2 text-xs underline text-blue-600">
            detail
          </a>
          <p :if={row.next_hint} class="text-xs text-amber-700 mt-0.5"><%= row.next_hint %></p>
        </li>
      </ul>
    </section>
    """
  end

  defp workspace_id_from_params(%{"workspace_id" => id}) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end

  defp workspace_id_from_params(_), do: 1
end
