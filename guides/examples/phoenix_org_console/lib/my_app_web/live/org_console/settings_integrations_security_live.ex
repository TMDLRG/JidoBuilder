defmodule MyAppWeb.OrgConsole.SettingsIntegrationsSecurityLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.OrgConsole.BaseLive
  alias MyAppWeb.OrgConsole.Components.ShellComponents

  @impl true
  def mount(_params, _session, socket) do
    integrations = [%{id: "slack-alerts", name: "Slack Alerts", enabled: true}]

    {:ok,
     socket
     |> BaseLive.init(%{
       title: "Settings, integrations, and security",
       subtitle: "Control access and connected services",
       integrations: integrations,
       empty: if(integrations == [], do: "No integrations connected.", else: nil)
     })}
  end

  @impl true
  def handle_event("toggle_advanced", _params, socket),
    do: {:noreply, BaseLive.toggle_advanced(socket)}

  def handle_event("stop_child", %{"id" => id}, socket) do
    msg =
      "Stopping this child process immediately halts active work and may trigger retries in parent workflows."

    {:noreply, BaseLive.open_confirm(socket, {:stop_child, id}, "Stop child process?", msg)}
  end

  def handle_event("disconnect", %{"id" => id}, socket) do
    msg =
      "Disconnecting this integration revokes tokens and blocks future syncs until reconnected."

    {:noreply,
     BaseLive.open_confirm(socket, {:disconnect, id}, "Delete integration connection?", msg)}
  end

  def handle_event("cancel_confirm", _params, socket),
    do: {:noreply, BaseLive.close_confirm(socket)}

  def handle_event(
        "confirm_action",
        _params,
        %{assigns: %{confirming: %{action: {:disconnect, id}}}} = socket
      ) do
    integrations = Enum.reject(socket.assigns.integrations, &(&1.id == id))

    {:noreply,
     socket
     |> BaseLive.close_confirm()
     |> assign(:integrations, integrations)
     |> assign(:empty, if(integrations == [], do: "No integrations connected.", else: nil))}
  end

  def handle_event(
        "confirm_action",
        _params,
        %{assigns: %{confirming: %{action: {:stop_child, id}}}} = socket
      ) do
    {:noreply,
     socket |> BaseLive.close_confirm() |> assign(:flash_notice, "Child #{id} stopped.")}
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
      <ul class="space-y-2">
        <li :for={integration <- @integrations} class="rounded border p-3">
          <p class="font-medium"><%= integration.name %></p>
          <div class="mt-2 flex gap-2">
            <button type="button" class="rounded border px-2 py-1" phx-click="stop_child" phx-value-id={integration.id}>
              Stop child
            </button>
            <button
              type="button"
              class="rounded border border-red-400 px-2 py-1 text-red-700"
              phx-click="disconnect"
              phx-value-id={integration.id}
            >
              Delete connection
            </button>
          </div>
        </li>
      </ul>
      <p :if={@flash_notice} class="text-sm text-emerald-700"><%= @flash_notice %></p>
    </ShellComponents.page>

    <ShellComponents.confirm_dialog confirming={@confirming} />
    """
  end
end
