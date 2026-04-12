defmodule JidoBuilderWeb.AgentLive do
  use JidoBuilderWeb, :live_view

  import Ecto.Query

  alias JidoBuilderCore.Agents.AgentInstance
  alias JidoBuilderCore.{Observability, Repo}
  alias JidoBuilderRuntime.EventBus

  @workspace_id 1
  @stream_limit 200

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    topics = [
      EventBus.workspace_activity_topic(@workspace_id),
      EventBus.agent_topic(@workspace_id, id)
    ]

    # Look up DB-persisted instance if available
    instance = Repo.one(from a in AgentInstance, where: a.name == ^id, limit: 1)
    agent_status = if instance, do: instance.status, else: "unknown"

    socket =
      socket
      |> assign(
        page_title: "Agent #{id}",
        agent_id: id,
        topics: topics,
        agent_status: agent_status
      )
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
    row = event |> Observability.translate_event() |> Map.put(:id, event.id)
    {:noreply, stream_insert(socket, :agent_events, row, at: 0, limit: @stream_limit)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Agent Detail / Activity Stream</.page_header>
    <p>Viewing agent <%= @agent_id %>.</p>

    <section class="mt-4 rounded border p-4">
      <h2 class="text-base font-semibold mb-2">Agent State</h2>
      <dl class="grid grid-cols-2 gap-2 text-sm">
        <dt class="text-zinc-500">Name</dt>
        <dd class="font-mono"><%= @agent_id %></dd>
        <dt class="text-zinc-500">Status</dt>
        <dd><%= @agent_status %></dd>
      </dl>
    </section>

    <section class="mt-4">
      <h2 class="text-base font-semibold">Agent Event Stream</h2>
      <ul id="agent-events" phx-update="stream" class="mt-2 space-y-1 text-sm">
        <li :for={{dom_id, row} <- @streams.agent_events} id={dom_id} class="py-1">
          <span class="font-mono"><%= row.label %></span>
          <span class="ml-2 text-xs text-zinc-600"><%= row.status %></span>
        </li>
      </ul>
    </section>
    """
  end
end
