defmodule MyAppWeb.OrgConsole.TeamsPodsLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.OrgConsole.BaseLive
  alias MyAppWeb.OrgConsole.Components.ShellComponents
  alias MyAppWeb.OrgConsole.Labels

  @impl true
  def mount(_params, _session, socket) do
    org = [%{department: "Operations", pods: ["Intake", "Escalations"]}]

    {:ok,
     socket
     |> BaseLive.init(%{
       title: "Departments and org chart",
       subtitle: "Browse team structure and pod ownership",
       org: org,
       empty: if(org == [], do: "No departments defined yet.", else: nil)
     })}
  end

  @impl true
  def handle_event("toggle_advanced", _params, socket),
    do: {:noreply, BaseLive.toggle_advanced(socket)}

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
      <ul class="space-y-2">
        <li :for={dept <- @org} class="rounded border p-3">
          <p class="font-medium"><%= dept.department %> <%= Labels.text(:department, @advanced_mode) %></p>
          <p class="text-sm text-slate-600">
            <%= Labels.text(:pod, @advanced_mode) %>s: <%= Enum.join(dept.pods, ", ") %>
          </p>
        </li>
      </ul>
    </ShellComponents.page>
    """
  end
end
