defmodule JidoBuilderWeb.Assignments.NewLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.Roster

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Dispatch Signal", agents: Roster.list(1), selected_agent: nil, result: nil)}
  end

  def handle_event("pick_agent", %{"id" => id}, socket), do: {:noreply, assign(socket, selected_agent: id)}
  def handle_event("dispatch", _params, socket), do: {:noreply, assign(socket, result: %{status: "queued", ms: 1})}

  def render(assigns) do
    ~H"""
    <.page_header>Dispatch Signal</.page_header>
    <section class="grid md:grid-cols-3 gap-4">
      <.card class="md:col-span-2">
        <:header>Select Agent</:header>
        <div class="grid md:grid-cols-2 gap-2">
          <button :for={agent <- @agents} phx-click="pick_agent" phx-value-id={agent.name} class={"ui-card-body border rounded text-left " <> if(@selected_agent == agent.name, do: "border-emerald-500", else: "border-zinc-200")}>{agent.name}</button>
        </div>
        <form id="dispatch-form" phx-submit="dispatch" class="mt-4 space-y-2">
          <.input_field name="dispatch[signal_type]" label="Signal type" value="ping" />
          <label class="ui-label">Payload JSON<textarea name="dispatch[payload]" class="ui-input font-mono" rows="6">{"message":"hello"}</textarea></label>
          <.button>Dispatch</.button>
        </form>
      </.card>
      <.card>
        <:header>Result</:header>
        <div :if={@result}><.badge variant="success">{@result.status}</.badge><pre class="text-xs">{inspect(@result)}</pre></div>
        <.empty_state :if={is_nil(@result)} title="No result yet" description="Dispatch a signal to view output." icon="command_line" />
      </.card>
    </section>
    """
  end
end
