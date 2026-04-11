defmodule JidoBuilderWeb.DashboardLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.EventBus

  @workspace_id 1
  @stream_limit 200

  @impl true
  def mount(_params, _session, socket) do
    topic = EventBus.workspace_activity_topic(@workspace_id)

    socket =
      socket
      |> assign(page_title: "Home Dashboard", workspace_topic: topic)
      |> stream(:activity_events, [], limit: -@stream_limit)

    if connected?(socket), do: Phoenix.PubSub.subscribe(JidoBuilder.PubSub, topic)

    {:ok, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    Phoenix.PubSub.unsubscribe(JidoBuilder.PubSub, socket.assigns.workspace_topic)
    :ok
  end

  @impl true
  def handle_info({:jido_event, event}, socket) do
    {:noreply, stream_insert(socket, :activity_events, event, at: 0, limit: @stream_limit)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p>Welcome to Jido Builder.</p>

    <section class="mt-4">
      <h2 class="text-base font-semibold">Workspace Activity</h2>
      <ul id="workspace-activity" phx-update="stream" class="mt-2 space-y-1 text-sm">
        <li :for={{dom_id, event} <- @streams.activity_events} id={dom_id}>
          <span class="font-mono"><%= event.event_name %></span>
          <span class="ml-2 text-zinc-600">status=<%= event.status %></span>
        </li>
      </ul>
    </section>
    """
  end
end
