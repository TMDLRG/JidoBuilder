defmodule JidoBuilderWeb.DashboardLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.Roster

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Dashboard",
       kpis: %{
         running_agents: length(Roster.list(1)),
         active_workflows: 0,
         signals_per_hour: 0,
         recent_errors: 0
       },
       activities: ["Runtime bridge connected", "Agent roster loaded"],
       errors: []
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Dashboard <:actions><.button>Hire Agent</.button></:actions></.page_header>
    <section class="grid md:grid-cols-4 gap-4">
      <.stat_card label="Running Agents" value={to_string(@kpis.running_agents)} icon="users" />
      <.stat_card label="Active Workflows" value={to_string(@kpis.active_workflows)} icon="folder" />
      <.stat_card label="Signals/hr" value={to_string(@kpis.signals_per_hour)} icon="signal" />
      <.stat_card label="Recent Errors" value={to_string(@kpis.recent_errors)} icon="exclamation_triangle" />
    </section>
    <section class="grid md:grid-cols-3 gap-4 mt-4">
      <.card><:header>Activity</:header><ul><li :for={row <- @activities}>{row}</li></ul></.card>
      <.card><:header>Quick Actions</:header><div class="flex gap-2"><.button>Hire Agent</.button><.button variant="secondary">Create Workflow</.button></div></.card>
      <.card><:header>Errors</:header><.empty_state title="No active errors" description="You're all clear." icon="check_circle" /></.card>
    </section>
    """
  end
end
