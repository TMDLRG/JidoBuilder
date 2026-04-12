defmodule JidoBuilderWeb.DebugLive do
  @moduledoc "Phase Final A.2 — Debug panel with live toggle and per-agent status."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Observability

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)

    {:ok,
     assign(socket,
       page_title: "Debug",
       workspace_id: workspace_id,
       errors: Observability.list_recent_errors(workspace_id, limit: 20),
       traces: Observability.list_recent_traces(workspace_id, limit: 20),
       debug_enabled: Application.get_env(:jido_builder_runtime, :debug_enabled, false),
       agents: list_agents(workspace_id)
     )}
  end

  @impl true
  def handle_event("toggle_debug", _params, socket) do
    enabled = not socket.assigns.debug_enabled
    Application.put_env(:jido_builder_runtime, :debug_enabled, enabled)
    {:noreply, assign(socket, debug_enabled: enabled)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <button id="debug-toggle" phx-click="toggle_debug" class="rounded border px-3 py-1 text-xs mt-2">
      Toggle debug (<%= if @debug_enabled, do: "on", else: "off" %>)
    </button>

    <section class="mt-4">
      <h2 class="text-sm font-semibold mb-2">Agent Debug Status</h2>
      <ul id="debug-agent-list" class="space-y-1 text-xs">
        <li :for={a <- @agents} class="border-b pb-1">
          <%= a.name %> — <%= if @debug_enabled, do: "debug:on", else: "debug:off" %>
        </li>
      </ul>
    </section>

    <section class="mt-4">
      <h2 class="text-sm font-semibold mb-2">Recent Errors</h2>
      <ul class="space-y-1 text-xs font-mono">
        <li :for={e <- @errors} class="border-b pb-1 text-red-700"><%= e.directive_type %>: <%= e.status %></li>
      </ul>
      <p :if={@errors == []} class="text-sm text-zinc-500">No recent errors.</p>
    </section>

    <section class="mt-6">
      <h2 class="text-sm font-semibold mb-2">Recent Traces</h2>
      <ul class="space-y-1 text-xs font-mono">
        <li :for={t <- @traces} class="border-b pb-1"><%= t.directive_type %>: <%= t.status %></li>
      </ul>
      <p :if={@traces == []} class="text-sm text-zinc-500">No recent traces.</p>
    </section>
    """
  end

  defp list_agents(workspace_id) do
    import Ecto.Query
    alias JidoBuilderCore.{Agents.AgentInstance, Repo}

    AgentInstance
    |> where([a], a.workspace_id == ^workspace_id)
    |> order_by([a], [asc: a.inserted_at])
    |> Repo.all()
  end

  defp wid(%{"workspace_id" => id}) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end

  defp wid(_), do: 1
end
