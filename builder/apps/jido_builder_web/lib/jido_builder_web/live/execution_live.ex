defmodule JidoBuilderWeb.ExecutionLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.EventBus

  @impl true
  def mount(params, _session, socket) do
    agent_id = Map.get(params, "agent_id")
    if connected?(socket), do: Phoenix.PubSub.subscribe(JidoBuilder.PubSub, EventBus.workspace_activity_topic(1))
    {:ok, assign(socket, page_title: "Execution", agent_id: agent_id, events: [], selected: nil)}
  end

  def handle_event("select_event", %{"id" => id}, socket), do: {:noreply, assign(socket, selected: id)}

  def handle_info({:jido_event, event}, socket) do
    {:noreply, update(socket, :events, &[event | &1])}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <.page_header>Execution Monitor</.page_header>
    <div class="grid grid-cols-12 gap-4">
      <.card class="col-span-9"><:header>Timeline</:header><div id="execution-timeline" phx-hook="ExecutionTimeline" data-events={Jason.encode!(@events)} class="h-48"></div></.card>
      <.card class="col-span-3"><:header>Event Detail</:header><pre class="text-xs"><%= inspect(@selected) %></pre></.card>
    </div>
    """
  end
end
