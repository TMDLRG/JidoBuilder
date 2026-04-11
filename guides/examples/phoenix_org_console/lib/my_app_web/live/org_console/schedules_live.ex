defmodule MyAppWeb.OrgConsole.SchedulesLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.OrgConsole.BaseLive
  alias MyAppWeb.OrgConsole.Components.ShellComponents

  @impl true
  def mount(_params, _session, socket) do
    schedules = [%{id: "daily-sync", cron: "0 9 * * *", task: "Daily Sync"}]

    {:ok,
     socket
     |> BaseLive.init(%{
       title: "Calendar & recurring tasks",
       subtitle: "Manage one-time and recurring work",
       schedules: schedules,
       empty: if(schedules == [], do: "No recurring tasks yet.", else: nil)
     })}
  end

  @impl true
  def handle_event("toggle_advanced", _params, socket),
    do: {:noreply, BaseLive.toggle_advanced(socket)}

  def handle_event("cancel_cron", %{"id" => id}, socket) do
    msg =
      "Canceling this recurring task stops all future runs. In-progress runs continue until complete."

    {:noreply, BaseLive.open_confirm(socket, {:cancel_cron, id}, "Cancel recurring task?", msg)}
  end

  def handle_event("cancel_confirm", _params, socket),
    do: {:noreply, BaseLive.close_confirm(socket)}

  def handle_event(
        "confirm_action",
        _params,
        %{assigns: %{confirming: %{action: {:cancel_cron, id}}}} = socket
      ) do
    schedules = Enum.reject(socket.assigns.schedules, &(&1.id == id))

    {:noreply,
     socket
     |> BaseLive.close_confirm()
     |> assign(:schedules, schedules)
     |> assign(:empty, if(schedules == [], do: "No recurring tasks yet.", else: nil))}
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
        <li :for={schedule <- @schedules} class="rounded border p-3">
          <p class="font-medium"><%= schedule.task %></p>
          <p class="text-sm text-slate-600">Cron: <%= schedule.cron %></p>
          <button
            type="button"
            class="mt-2 rounded border border-red-400 px-2 py-1 text-red-700"
            phx-click="cancel_cron"
            phx-value-id={schedule.id}
          >
            Cancel recurring task
          </button>
        </li>
      </ul>
    </ShellComponents.page>

    <ShellComponents.confirm_dialog confirming={@confirming} />
    """
  end
end
