defmodule JidoBuilderWeb.RosterLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.{EventBus, Roster}

  @impl true
  def mount(_params, _session, socket) do
    agents = Roster.list(1)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(JidoBuilder.PubSub, EventBus.workspace_activity_topic(1))
    end

    socket =
      socket
      |> assign(page_title: "Agents", show_hire: false, pending_stop: nil, form_error: nil)
      |> stream(:agents, agents)

    {:ok, socket}
  end

  @impl true
  def handle_event("open_hire", _, socket), do: {:noreply, assign(socket, show_hire: true)}
  def handle_event("close_hire", _, socket), do: {:noreply, assign(socket, show_hire: false)}

  def handle_event("hire_agent", %{"hire" => %{"name" => name}}, socket) do
    actor = socket.assigns.current_user.email

    case Roster.hire(1, String.trim(name), actor) do
      {:ok, agent_instance} ->
        {:noreply,
         socket
         |> assign(show_hire: false, form_error: nil)
         |> stream_insert(:agents, agent_instance, at: 0)}

      {:error, error} ->
        {:noreply, assign(socket, form_error: inspect(error))}
    end
  end

  def handle_event("request_stop", %{"name" => name}, socket) do
    {:noreply, assign(socket, pending_stop: name)}
  end

  def handle_event("cancel_stop", _, socket), do: {:noreply, assign(socket, pending_stop: nil)}

  def handle_event("confirm_stop", %{"name" => agent_name}, socket) do
    actor = socket.assigns.current_user.email

    case Roster.stop(1, agent_name, actor) do
      {:ok, instance} ->
        {:noreply,
         socket
         |> assign(pending_stop: nil, form_error: nil)
         |> stream_delete(:agents, instance)}

      {:error, error} ->
        {:noreply, assign(socket, form_error: inspect(error))}
    end
  end

  @impl true
  def handle_info({:roster_hire, agent_instance}, socket) do
    {:noreply, stream_insert(socket, :agents, agent_instance, at: 0)}
  end

  def handle_info({:roster_stop, agent_instance}, socket) do
    {:noreply, stream_delete(socket, :agents, agent_instance)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Agents <:actions><button phx-click="open_hire" class="ui-btn primary">Hire</button></:actions></.page_header>

    <p :if={@form_error} class="mb-4 text-sm text-red-600">{@form_error}</p>

    <section id="roster-agents" phx-update="stream" class="grid md:grid-cols-3 gap-4">
      <div :for={{dom_id, agent} <- @streams.agents} id={dom_id}>
        <.card>
          <:header><div class="flex justify-between"><span>{agent.name}</span><.badge variant="success">{agent.status}</.badge></div></:header>
          <div class="text-xs text-zinc-500">template: bare</div>
          <:footer><.link navigate={~p"/agents/#{agent.name}"} class="text-sm">View</.link> <button phx-click="request_stop" phx-value-name={agent.name} class="text-sm text-red-600">Stop</button></:footer>
        </.card>
      </div>
    </section>

    <.modal id="hire-modal" show={@show_hire}>
      <.card>
        <:header>Hire Agent</:header>
        <form id="hire-form" phx-submit="hire_agent" class="space-y-3">
          <.input_field name="hire[name]" label="Agent name" />
          <div class="flex gap-2 mt-2">
            <.button>Hire</.button>
            <button phx-click="close_hire" type="button" class="ui-btn secondary">Cancel</button>
          </div>
        </form>
      </.card>
    </.modal>

    <.modal id="stop-modal" show={not is_nil(@pending_stop)}>
      <.card>
        <:header>Stop Agent</:header>
        <p>Stop {@pending_stop}? In-flight tasks will be cancelled.</p>
        <:footer>
          <button phx-click="confirm_stop" phx-value-name={@pending_stop} class="ui-btn danger">Stop</button>
          <button phx-click="cancel_stop" class="ui-btn secondary">Cancel</button>
        </:footer>
      </.card>
    </.modal>
    """
  end
end
