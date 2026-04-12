defmodule JidoBuilderWeb.Assignments.NewLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.{Hiring, Roster, Signals}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Dispatch Signal", agents: Roster.list(1), selected_agent: nil, result: nil, error: nil)}
  end

  @impl true
  def handle_event("pick_agent", %{"id" => id}, socket), do: {:noreply, assign(socket, selected_agent: id)}

  @impl true
  def handle_event("dispatch", %{"dispatch" => %{"signal_type" => sig_type} = params}, socket) do
    user = socket.assigns.current_user
    target = socket.assigns.selected_agent || Map.get(params, "target_agent")
    do_dispatch(socket, user, target, sig_type, Map.get(params, "payload", "{}"))
  end

  defp do_dispatch(socket, _user, nil, _sig_type, _payload_str) do
    {:noreply, assign(socket, error: "Select an agent first.", result: nil)}
  end

  defp do_dispatch(socket, user, target, sig_type, payload_str) do
    payload =
      case Jason.decode(payload_str) do
        {:ok, map} when is_map(map) -> map
        _ -> %{}
      end

    context = %{workspace_id: 1, actor: user.email}

    with {:ok, server} <- Hiring.whereis(context, target),
         {:ok, signal} <- Signals.new(context, sig_type, payload),
         :ok <- Signals.cast(context, server, signal) do
      {:noreply, assign(socket, result: "dispatched async — signal enqueued", error: nil)}
    else
      {:error, reason} ->
        {:noreply, assign(socket, error: inspect(reason), result: nil)}
    end
  end

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
        <form id="dispatch-form" phx-submit="dispatch" class="mt-4 space-y-2">
          <.input_field name="dispatch[signal_type]" label="Signal type" value="ping" />
          <label class="ui-label block text-sm">
            <span class="block text-xs font-medium text-zinc-600 mb-1">Payload JSON</span>
            <textarea name="dispatch[payload]" class="ui-input font-mono" rows="6">{Jason.encode!(%{"message" => "hello"})}</textarea>
          </label>
          <.button>Dispatch</.button>
        </form>
      </.card>
      <.card>
        <:header>Result</:header>
        <div :if={@result} class="rounded bg-green-50 border border-green-200 p-3 text-sm">
          <p class="font-semibold mb-1">dispatched — result</p>
          <pre class="font-mono text-xs whitespace-pre-wrap">{@result}</pre>
        </div>
        <div :if={@error} class="rounded bg-red-50 border border-red-200 p-3 text-sm text-red-700">{@error}</div>
        <.empty_state :if={is_nil(@result) and is_nil(@error)} title="No result yet" description="Dispatch a signal to view output." icon="command_line" />
      </.card>
    </section>
    """
  end
end
