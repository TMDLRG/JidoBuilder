defmodule MyAppWeb.OrgConsole.TeamOverviewLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.OrgConsole.BaseLive
  alias MyAppWeb.OrgConsole.Components.ShellComponents
  alias MyAppWeb.OrgConsole.Labels

  @impl true
  def mount(_params, _session, socket) do
    teams = [%{name: "Operations", active: 6}, %{name: "Growth", active: 4}]

    {:ok,
     socket
     |> BaseLive.init(%{
       title: "Team Overview",
       subtitle: "How your departments are performing right now",
       teams: teams,
       empty: if(teams == [], do: "No teams are active yet.", else: nil)
     })}
  end

  @impl true
  def handle_event("toggle_advanced", _params, socket),
    do: {:noreply, BaseLive.toggle_advanced(socket)}

  def handle_event("refresh", _params, socket) do
    {:noreply, socket |> assign(:loading, true) |> assign(:loading, false) |> assign(:error, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <ShellComponents.page
      title={@title}
      subtitle={@subtitle}
      loading={@loading}
      error={@error}
      empty={@empty}
      advanced_mode={@advanced_mode}
    >
      <:actions>
        <button type="button" class="rounded border px-3 py-1" phx-click="refresh">Refresh</button>
      </:actions>

      <ul class="space-y-2">
        <li :for={team <- @teams} class="rounded border p-3">
          <p class="font-medium"><%= team.name %></p>
          <p class="text-sm text-slate-600">
            <%= team.active %> active <%= Labels.text(:agent, @advanced_mode) %>s
          </p>
        </li>
      </ul>
    </ShellComponents.page>
    """
  end
end
