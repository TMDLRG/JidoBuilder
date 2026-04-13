defmodule JidoBuilderWeb.DashboardLive do
  use JidoBuilderWeb, :live_view

  import Ecto.Query

  alias JidoBuilderRuntime.Roster

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(JidoBuilder.PubSub, "workspace:1")
    end

    {:ok,
     assign(socket,
       page_title: "Dashboard",
       kpis: load_kpis(1),
       activities: initial_activities(),
       errors: JidoBuilderCore.Observability.list_recent_errors(1, limit: 5)
     )}
  end

  @impl true
  def handle_info({:roster_hire, agent}, socket) do
    kpis = %{socket.assigns.kpis | running_agents: socket.assigns.kpis.running_agents + 1}
    activities = prepend_activity(socket.assigns.activities, "Agent #{agent.name} hired")
    {:noreply, assign(socket, kpis: kpis, activities: activities)}
  end

  def handle_info({:roster_stop, agent}, socket) do
    kpis = %{socket.assigns.kpis | running_agents: max(0, socket.assigns.kpis.running_agents - 1)}
    activities = prepend_activity(socket.assigns.activities, "Agent #{agent.name} stopped")
    {:noreply, assign(socket, kpis: kpis, activities: activities)}
  end

  def handle_info({:jido_event, event}, socket) do
    kind = event[:kind] || event["kind"] || "event"
    agent = event[:agent_id] || event["agent_id"] || ""
    label = "#{kind} — #{agent}" |> String.trim_trailing(" — ")
    activities = prepend_activity(socket.assigns.activities, label)
    {:noreply, assign(socket, activities: activities)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Dashboard <:actions><.link navigate={~p"/roster"} class="ui-btn primary">Hire Agent</.link></:actions></.page_header>
    <section class="grid md:grid-cols-4 gap-4">
      <.stat_card label="Running Agents" value={to_string(@kpis.running_agents)} icon="users" />
      <.stat_card label="Active Workflows" value={to_string(@kpis.active_workflows)} icon="play" />
      <.stat_card label="Signals/hr" value={to_string(@kpis.signals_per_hour)} icon="signal" />
      <.stat_card label="Recent Errors" value={to_string(@kpis.recent_errors)} icon="exclamation_triangle" />
    </section>
    <section class="grid md:grid-cols-3 gap-4 mt-6">
      <.card>
        <:header>Activity</:header>
        <ul class="space-y-1.5 text-sm text-zinc-600 max-h-48 overflow-y-auto">
          <li :for={row <- @activities} class="flex items-center gap-2">
            <.icon name="check_circle" class="w-3.5 h-3.5 text-emerald-500 shrink-0" />
            {row}
          </li>
        </ul>
        <p :if={@activities == []} class="text-sm text-zinc-400">No activity yet. Hire an agent or dispatch a signal.</p>
      </.card>
      <.card>
        <:header>Quick Actions</:header>
        <div class="flex flex-wrap gap-2">
          <.link navigate={~p"/roster"} class="ui-btn primary">Hire Agent</.link>
          <.link navigate={~p"/workflows"} class="ui-btn secondary">Create Workflow</.link>
          <.link navigate={~p"/assignments/new"} class="ui-btn secondary">Dispatch Signal</.link>
        </div>
      </.card>
      <.card>
        <:header>Errors</:header>
        <ul :if={@errors != []} class="space-y-1 text-xs">
          <li :for={e <- Enum.take(@errors, 5)} class="border-b pb-1 text-red-700">{e.signal_type}: {e.direction}</li>
        </ul>
        <div :if={@errors != []}>
          <.link navigate={~p"/debug"} class="text-xs text-blue-600 hover:underline mt-2 inline-block">View all in Debug Console &rarr;</.link>
        </div>
        <.empty_state :if={@errors == []} title="No active errors" description="You're all clear." icon="check_circle" />
      </.card>
    </section>
    """
  end

  defp load_kpis(workspace_id) do
    %{
      running_agents: length(Roster.list(workspace_id)),
      active_workflows: length(JidoBuilderCore.Workflows.list_workflows(workspace_id)),
      signals_per_hour: signal_count_last_hour(workspace_id),
      recent_errors: length(JidoBuilderCore.Observability.list_recent_errors(workspace_id, limit: 100))
    }
  end

  defp initial_activities do
    ["Runtime bridge connected"]
  end

  defp prepend_activity(activities, label) do
    [label | Enum.take(activities, 19)]
  end

  defp signal_count_last_hour(workspace_id) do
    cutoff = DateTime.add(DateTime.utc_now(), -3600, :second)

    JidoBuilderCore.Repo.aggregate(
      from(s in JidoBuilderCore.Observability.SignalLog,
        where: s.workspace_id == ^workspace_id and s.inserted_at >= ^cutoff
      ),
      :count
    )
  end
end
