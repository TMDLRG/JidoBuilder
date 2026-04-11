defmodule MyAppWeb.OrgConsole.AgentProfileLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.OrgConsole.BaseLive
  alias MyAppWeb.OrgConsole.Components.ShellComponents

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    profile = %{id: id, name: "Casey", status: "Available", skills: ["Escalations", "QA"]}

    {:ok,
     socket
     |> BaseLive.init(%{
       title: "Employee profile",
       subtitle: "Role, current workload, and skills",
       profile: profile,
       empty: nil
     })}
  end

  @impl true
  def handle_event("toggle_advanced", _params, socket),
    do: {:noreply, BaseLive.toggle_advanced(socket)}

  def handle_event("mark_busy", _params, socket),
    do: {:noreply, update(socket, :profile, &Map.put(&1, :status, "Busy"))}

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
        <button type="button" class="rounded border px-3 py-1" phx-click="mark_busy">Mark busy</button>
      </:actions>

      <article class="space-y-2 rounded border p-4">
        <p><strong>ID:</strong> <%= @profile.id %></p>
        <p><strong>Name:</strong> <%= @profile.name %></p>
        <p><strong>Status:</strong> <%= @profile.status %></p>
        <p><strong>Skills:</strong> <%= Enum.join(@profile.skills, ", ") %></p>
      </article>
    </ShellComponents.page>
    """
  end
end
