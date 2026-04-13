defmodule JidoBuilderWeb.AgentLive do
  @moduledoc """
  Story 3.3 — Agent detail page with health metrics, signal history,
  state inspector, and inline dispatch.
  """
  use JidoBuilderWeb, :live_view

  import Ecto.Query

  alias JidoBuilderCore.{Observability, Repo, Templates}
  alias JidoBuilderCore.Agents.AgentInstance
  alias JidoBuilderRuntime.{EventBus, Hiring, Roster}

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    workspace_id = workspace_id_from_params(params)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(JidoBuilder.PubSub, EventBus.agent_state_topic(workspace_id, id))
    end

    instance = load_instance(workspace_id, id)
    health = check_health(workspace_id, id)
    signal_count = if instance, do: Observability.count_agent_signals(instance.id), else: 0
    signals = if instance, do: Observability.list_agent_signals(instance.id, limit: 50), else: []

    {:ok,
     assign(socket,
       page_title: "Agent #{id}",
       workspace_id: workspace_id,
       agent_id: id,
       instance: instance,
       active_tab: Map.get(params, "tab", "overview"),
       agent_state: %{},
       health: health,
       signal_count: signal_count,
       error_count: length(Observability.list_recent_errors(workspace_id, limit: 100)),
       signals: signals,
       template_routes: load_template_routes(instance)
     )}
  end

  @impl true
  def handle_event("tab", %{"name" => tab}, socket), do: {:noreply, assign(socket, active_tab: tab)}

  def handle_event("stop_agent", _params, socket) do
    case Roster.stop(socket.assigns.workspace_id, socket.assigns.agent_id) do
      {:ok, _} -> {:noreply, push_navigate(socket, to: ~p"/roster")}
      {:error, _} -> {:noreply, push_navigate(socket, to: ~p"/roster")}
      _ -> {:noreply, push_navigate(socket, to: ~p"/roster")}
    end
  end

  @impl true
  def handle_info({:agent_state_changed, payload}, socket) do
    {:noreply, assign(socket, agent_state: payload.state || %{})}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp load_instance(workspace_id, agent_name) do
    Repo.one(
      from a in AgentInstance,
        where: a.workspace_id == ^workspace_id and a.name == ^agent_name,
        order_by: [desc: a.inserted_at],
        limit: 1
    )
  end

  defp check_health(workspace_id, agent_id) do
    context = %{workspace_id: workspace_id, actor: "health_check"}

    case Hiring.whereis(context, agent_id) do
      {:ok, pid} when is_pid(pid) -> if Process.alive?(pid), do: "healthy", else: "degraded"
      _ -> "degraded"
    end
  end

  defp workspace_id_from_params(%{"workspace_id" => id}) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end

  defp workspace_id_from_params(_), do: 1

  defp load_template_routes(nil), do: []

  defp load_template_routes(instance) do
    if instance.template_id do
      Templates.list_routes(instance.template_id)
    else
      []
    end
  rescue
    _ -> []
  end

  defp format_timestamp(%NaiveDateTime{} = ts), do: Calendar.strftime(ts, "%H:%M:%S")
  defp format_timestamp(_), do: "—"

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Agent Detail</.page_header>

    <div class="flex items-center gap-3 mb-4">
      <h2 class="text-lg font-semibold">{@agent_id}</h2>
      <.badge variant={if @instance && @instance.status == "running", do: "success", else: "default"}>
        {if @instance, do: @instance.status, else: "unknown"}
      </.badge>
      <.badge variant={if @health == "healthy", do: "success", else: "warning"}>
        {@health}
      </.badge>
      <button :if={@instance && @instance.status == "running"} phx-click="stop_agent" class="ml-auto text-xs text-red-500 hover:text-red-700 border border-red-300 px-2 py-1 rounded" data-confirm="Stop this agent?">Stop Agent</button>
    </div>

    <nav class="mb-4 flex gap-2 text-xs">
      <button :for={tab <- ["overview", "state", "signals", "actions"]}
        phx-click="tab" phx-value-name={tab}
        class={["px-3 py-1.5 rounded", if(@active_tab == tab, do: "bg-zinc-800 text-white", else: "bg-zinc-200 text-zinc-700")]}>
        {String.capitalize(tab)}
      </button>
    </nav>

    <.card :if={@active_tab == "overview"}>
      <:header>Overview</:header>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
        <div>
          <div class="text-2xl font-bold">{@signal_count}</div>
          <div class="text-xs text-zinc-500">Signals</div>
        </div>
        <div>
          <div class="text-2xl font-bold">{@error_count}</div>
          <div class="text-xs text-zinc-500">Errors</div>
        </div>
        <div>
          <div class="text-sm font-medium">{@health}</div>
          <div class="text-xs text-zinc-500">Health</div>
        </div>
        <div>
          <div class="text-sm font-medium">{if @instance, do: @instance.status, else: "—"}</div>
          <div class="text-xs text-zinc-500">Status</div>
        </div>
      </div>
    </.card>

    <.card :if={@active_tab == "state"}>
      <:header>State Inspector</:header>
      <div id="agent-json-tree" phx-hook="JsonTree" data-json={Jason.encode!(@agent_state)}></div>
    </.card>

    <.card :if={@active_tab == "signals"}>
      <:header>Signal History</:header>
      <div :if={@signals == []} class="text-sm text-zinc-400 italic py-4 text-center">No signals yet.</div>
      <table :if={@signals != []} class="w-full text-sm">
        <thead>
          <tr class="text-left text-xs text-zinc-500 border-b">
            <th class="py-2 px-2">Time</th>
            <th class="py-2 px-2">Signal Type</th>
            <th class="py-2 px-2">Direction</th>
            <th class="py-2 px-2">Correlation ID</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={sig <- @signals} class="border-b border-zinc-100">
            <td class="py-2 px-2 text-xs text-zinc-500">{format_timestamp(sig.inserted_at)}</td>
            <td class="py-2 px-2 font-mono text-xs">{sig.signal_type}</td>
            <td class="py-2 px-2 text-xs">{sig.direction}</td>
            <td class="py-2 px-2 text-xs text-zinc-400 truncate max-w-[120px]">{sig.correlation_id || "—"}</td>
          </tr>
        </tbody>
      </table>
    </.card>

    <.card :if={@active_tab == "actions"}>
      <:header>Routes &amp; Actions</:header>
      <div :if={@template_routes != []} class="space-y-1">
        <div :for={route <- @template_routes} class="flex items-center gap-2 py-1 border-b border-zinc-100 text-sm">
          <span class="font-mono text-xs bg-zinc-100 px-2 py-0.5 rounded">{route.signal_type}</span>
          <span class="text-zinc-400">&rarr;</span>
          <span class="font-mono text-xs">{route.action_slug}</span>
        </div>
      </div>
      <p :if={@template_routes == []} class="text-sm text-zinc-500">No routes configured. Agent uses bare template.</p>
      <div class="mt-3 pt-2 border-t">
        <.link navigate={~p"/assignments/new"} class="text-xs text-blue-600 hover:underline">Dispatch a signal to this agent &rarr;</.link>
      </div>
    </.card>
    """
  end
end
