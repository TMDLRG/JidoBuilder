defmodule MyAppWeb.OrgConsole.RosterLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.OrgConsole.BaseLive
  alias MyAppWeb.OrgConsole.Components.ShellComponents
  alias MyAppWeb.OrgConsole.Labels

  @impl true
  def mount(_params, _session, socket) do
    roster = [%{id: "emp-1", name: "Casey", team: "Operations"}]

    {:ok,
     socket
     |> BaseLive.init(%{
       title: "Roster",
       subtitle: "Hire, fire, and move people between teams",
       roster: roster,
       empty: if(roster == [], do: "No employees in the roster.", else: nil)
     })}
  end

  @impl true
  def handle_event("toggle_advanced", _params, socket),
    do: {:noreply, BaseLive.toggle_advanced(socket)}

  def handle_event("hire", _params, socket),
    do: {:noreply, assign(socket, :flash_notice, "Hiring request saved.")}

  def handle_event("reassign", %{"id" => id}, socket),
    do: {:noreply, assign(socket, :flash_notice, "#{id} reassigned.")}

  def handle_event("fire", %{"id" => id}, socket) do
    message =
      "This removes the employee from active workflows, unassigns open work, and records an offboarding event."

    {:noreply,
     BaseLive.open_confirm(socket, {:fire, id}, "Confirm employee termination", message)}
  end

  def handle_event("cancel_confirm", _params, socket),
    do: {:noreply, BaseLive.close_confirm(socket)}

  def handle_event(
        "confirm_action",
        _params,
        %{assigns: %{confirming: %{action: {:fire, id}}}} = socket
      ) do
    roster = Enum.reject(socket.assigns.roster, &(&1.id == id))

    {:noreply,
     socket
     |> assign(:roster, roster)
     |> assign(:empty, if(roster == [], do: "No employees in the roster.", else: nil))
     |> assign(:flash_notice, "#{id} was removed from the roster.")
     |> BaseLive.close_confirm()}
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
        <button type="button" class="rounded border px-3 py-1" phx-click="hire">
          Hire <%= Labels.text(:agent, @advanced_mode) %>
        </button>
      </:actions>

      <ul class="space-y-2">
        <li :for={member <- @roster} class="rounded border p-3">
          <p class="font-medium"><%= member.name %></p>
          <p class="text-sm text-slate-600">Team: <%= member.team %></p>
          <div class="mt-2 flex gap-2">
            <button type="button" class="rounded border px-2 py-1" phx-click="reassign" phx-value-id={member.id}>
              Reassign
            </button>
            <button type="button" class="rounded border border-red-400 px-2 py-1 text-red-700" phx-click="fire" phx-value-id={member.id}>
              Fire
            </button>
          </div>
        </li>
      </ul>
    </ShellComponents.page>

    <ShellComponents.confirm_dialog confirming={@confirming} />
    """
  end
end
