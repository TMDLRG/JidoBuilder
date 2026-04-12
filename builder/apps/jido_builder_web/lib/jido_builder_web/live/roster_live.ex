defmodule JidoBuilderWeb.RosterLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.Roster

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Agents", agents: Roster.list(1), show_hire: false, pending_stop: nil)}
  end

  def handle_event("open_hire", _, socket), do: {:noreply, assign(socket, show_hire: true)}
  def handle_event("close_hire", _, socket), do: {:noreply, assign(socket, show_hire: false)}
  def handle_event("request_stop", %{"name" => name}, socket), do: {:noreply, assign(socket, pending_stop: name)}
  def handle_event("cancel_stop", _, socket), do: {:noreply, assign(socket, pending_stop: nil)}

  def render(assigns) do
    ~H"""
    <.page_header>Agents <:actions><button phx-click="open_hire" class="ui-btn primary">Hire</button></:actions></.page_header>

    <div :if={@agents == []}><.empty_state title="No agents running" description="Hire your first runtime worker" icon="users" /></div>

    <section class="grid md:grid-cols-3 gap-4" :if={@agents != []}>
      <.card :for={agent <- @agents}>
        <:header><div class="flex justify-between"><span>{agent.name}</span><.badge variant="success">{agent.status}</.badge></div></:header>
        <div class="text-xs text-zinc-500">template: bare</div>
        <:footer><.link navigate={~p"/agents/#{agent.name}"} class="text-sm">View</.link> <button phx-click="request_stop" phx-value-name={agent.name} class="text-sm text-red-600">Stop</button></:footer>
      </.card>
    </section>

    <.modal id="hire-modal" show={@show_hire}><.card><:header>Hire Agent</:header><p>Use the assignment console to create workers.</p><:footer><button phx-click="close_hire" class="ui-btn secondary">Close</button></:footer></.card></.modal>
    <.modal id="stop-modal" show={not is_nil(@pending_stop)}><.card><:header>Stop Agent</:header><p>Stop {@pending_stop}?</p><:footer><button phx-click="cancel_stop" class="ui-btn secondary">Cancel</button></:footer></.card></.modal>
    """
  end
end
