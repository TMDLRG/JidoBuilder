defmodule JidoBuilderWeb.RosterLive do
  @moduledoc """
  Phase 1.1 — Roster / Hire Wizard.

  Displays all running agents for the current workspace and lets the
  operator hire a new bare-runtime agent by name.  Stop confirmation is
  handled in Phase 1.4.
  """
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.{EventBus, Roster}

  @impl true
  def mount(params, _session, socket) do
    workspace_id = workspace_id_from_params(params)
    agents = Roster.list(workspace_id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(JidoBuilder.PubSub, EventBus.workspace_activity_topic(workspace_id))
    end

    socket =
      socket
      |> assign(page_title: "Roster / Hire Wizard", workspace_id: workspace_id, form_error: nil)
      |> stream(:agents, agents)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_event("hire", %{"hire" => %{"display_name" => name}}, socket) do
    workspace_id = socket.assigns.workspace_id
    actor = socket.assigns.current_user.email

    case Roster.hire(workspace_id, String.trim(name), actor) do
      {:ok, agent_instance} ->
        {:noreply,
         socket
         |> assign(form_error: nil)
         |> stream_insert(:agents, agent_instance, at: 0)}

      {:error, error} ->
        {:noreply, assign(socket, form_error: inspect(error))}
    end
  end

  def handle_event("confirm_stop", %{"name" => agent_name}, socket) do
    workspace_id = socket.assigns.workspace_id
    actor = socket.assigns.current_user.email

    case Roster.stop(workspace_id, agent_name, actor) do
      {:ok, instance} ->
        {:noreply,
         socket
         |> assign(pending_stop: nil, form_error: nil)
         |> stream_delete(:agents, instance)}

      {:error, error} ->
        {:noreply, assign(socket, form_error: inspect(error))}
    end
  end

  def handle_event("request_stop", %{"name" => agent_name}, socket) do
    {:noreply, assign(socket, pending_stop: agent_name)}
  end

  def handle_event("cancel_stop", _params, socket) do
    {:noreply, assign(socket, pending_stop: nil)}
  end

  @impl true
  def handle_info({:roster_hire, agent_instance}, socket) do
    {:noreply, stream_insert(socket, :agents, agent_instance, at: 0)}
  end

  def handle_info({:roster_stop, agent_instance}, socket) do
    {:noreply, stream_delete(socket, :agents, agent_instance)}
  end

  def handle_info({:jido_event, _event}, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    assigns = Map.put_new(assigns, :pending_stop, nil)

    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <section class="mb-6">
      <h2 class="text-base font-semibold mb-2">Hire a Worker</h2>
      <form id="hire-form" phx-submit="hire" class="flex items-center gap-2">
        <input
          type="text"
          name="hire[display_name]"
          placeholder="Agent name"
          required
          class="border rounded px-2 py-1 text-sm"
        />
        <button type="submit" class="rounded bg-zinc-900 px-3 py-1 text-white text-sm">
          Hire
        </button>
      </form>
      <p :if={@form_error} class="mt-2 text-sm text-red-600"><%= @form_error %></p>
    </section>

    <section>
      <h2 class="text-base font-semibold mb-2">Running Workers</h2>
      <ul id="roster-agents" phx-update="stream" class="space-y-1 text-sm">
        <li
          :for={{dom_id, agent} <- @streams.agents}
          id={dom_id}
          class="flex items-center gap-4 py-1 border-b last:border-0"
        >
          <span class="font-mono"><%= agent.name %></span>
          <span class="text-zinc-500"><%= agent.status %></span>
          <button
            phx-click="request_stop"
            phx-value-name={agent.name}
            class="ml-auto text-xs text-red-600 hover:underline"
          >
            Stop
          </button>
        </li>
      </ul>
    </section>

    <div
      :if={@pending_stop}
      id="stop-confirm-modal"
      class="fixed inset-0 flex items-center justify-center bg-black/40"
    >
      <div class="bg-white rounded shadow p-6 max-w-sm w-full">
        <p class="text-sm font-medium mb-4">
          Stop worker <span class="font-mono"><%= @pending_stop %></span>?
          In-flight tasks will be cancelled.
        </p>
        <div class="flex gap-3 justify-end">
          <button phx-click="cancel_stop" class="text-sm text-zinc-600 hover:underline">
            Cancel
          </button>
          <button
            phx-click="confirm_stop"
            phx-value-name={@pending_stop}
            class="rounded bg-red-600 px-3 py-1 text-white text-sm"
          >
            Stop
          </button>
        </div>
      </div>
    </div>
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
