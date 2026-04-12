defmodule JidoBuilderWeb.AgentLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.EventBus

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(JidoBuilder.PubSub, EventBus.agent_state_topic(1, id))
    end

    {:ok,
     assign(socket,
       page_title: "Agent #{id}",
       agent_id: id,
       active_tab: "overview",
       agent_state: %{},
       events: []
     )}
  end

  @impl true
  def handle_event("tab", %{"name" => tab}, socket), do: {:noreply, assign(socket, active_tab: tab)}

  @impl true
  def handle_info({:agent_state_changed, payload}, socket), do: {:noreply, assign(socket, agent_state: payload.state || %{})}
  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Agent Detail</.page_header>
    <.tabs active_tab={@active_tab} items={["overview", "state", "signals", "actions"]} />
    <nav class="mb-4 flex gap-2 text-xs">
      <button phx-click="tab" phx-value-name="overview">Overview</button>
      <button phx-click="tab" phx-value-name="state">State Inspector</button>
      <button phx-click="tab" phx-value-name="signals">Signal History</button>
      <button phx-click="tab" phx-value-name="actions">Action Log</button>
    </nav>
    <.card :if={@active_tab == "overview"}><:header>Overview</:header><p>ID: {@agent_id}</p></.card>
    <.card :if={@active_tab == "state"}><:header>State Inspector</:header><div id="agent-json-tree" phx-hook="JsonTree" data-json={Jason.encode!(@agent_state)}></div></.card>
    <.card :if={@active_tab == "signals"}><:header>Signal History</:header><.table id="signals-table" rows={@events}><:col :let={e}>{inspect(e)}</:col></.table></.card>
    <.card :if={@active_tab == "actions"}><:header>Action Log</:header><p class="text-sm text-zinc-500">No actions yet.</p></.card>
    """
  end
end
