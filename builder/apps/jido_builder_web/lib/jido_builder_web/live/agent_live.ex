defmodule JidoBuilderWeb.AgentLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.EventBus

  @workspace_id 1
  @stream_limit 200

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    topics = [
      EventBus.workspace_activity_topic(@workspace_id),
      EventBus.agent_topic(@workspace_id, id)
    ]

    socket =
      socket
      |> assign(page_title: "Agent #{id}", agent_id: id, topics: topics)
      |> stream(:agent_events, [], limit: -@stream_limit)

    if connected?(socket) do
      Enum.each(topics, &Phoenix.PubSub.subscribe(JidoBuilder.PubSub, &1))
    end

    {:ok, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    Enum.each(socket.assigns.topics, &Phoenix.PubSub.unsubscribe(JidoBuilder.PubSub, &1))
    :ok
  end

  @impl true
  def handle_info({:jido_event, event}, socket) do
    {:noreply, stream_insert(socket, :agent_events, event, at: 0, limit: @stream_limit)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Agent Detail / Activity Stream</.page_header>
    <p>Viewing agent <%= @agent_id %>.</p>

    <section class="mt-4">
      <h2 class="text-base font-semibold">Agent Event Stream</h2>
      <ul id="agent-events" phx-update="stream" class="mt-2 space-y-1 text-sm">
        <li :for={{dom_id, event} <- @streams.agent_events} id={dom_id}>
          <span class="font-mono"><%= event.event_name %></span>
          <span class="ml-2 text-zinc-600">status=<%= event.status %></span>
        </li>
      </ul>
    </section>
    """
  end
end
