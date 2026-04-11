defmodule MyAppWeb.OrgConsole.WatchersSensorsLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.OrgConsole.BaseLive
  alias MyAppWeb.OrgConsole.Components.ShellComponents
  alias MyAppWeb.OrgConsole.Labels

  @impl true
  def mount(_params, _session, socket) do
    monitors = [%{name: "Latency watchdog", status: "Healthy"}]

    {:ok,
     socket
     |> BaseLive.init(%{
       title: "Monitors",
       subtitle: "Track events and service health",
       monitors: monitors,
       empty: if(monitors == [], do: "No monitors configured.", else: nil)
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
        <li :for={monitor <- @monitors} class="rounded border p-3">
          <p class="font-medium"><%= monitor.name %></p>
          <p class="text-sm text-slate-600">
            <%= Labels.text(:watcher, @advanced_mode) %> status: <%= monitor.status %>
          </p>
        </li>
      </ul>
    </ShellComponents.page>
    """
  end
end
