defmodule MyAppWeb.OrgConsole.AssignmentComposerLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.OrgConsole.BaseLive
  alias MyAppWeb.OrgConsole.Components.ShellComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> BaseLive.init(%{
       title: "Assign work",
       subtitle: "Create and send assignments to your team",
       draft: %{title: "", target: ""},
       empty: nil
     })}
  end

  @impl true
  def handle_event("toggle_advanced", _params, socket),
    do: {:noreply, BaseLive.toggle_advanced(socket)}

  def handle_event("update", %{"assignment" => params}, socket),
    do: {:noreply, assign(socket, :draft, params)}

  def handle_event("submit", _params, socket),
    do: {:noreply, assign(socket, :flash_notice, "Assignment queued.")}

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
        <button type="button" class="rounded border px-3 py-1" phx-click="submit">Assign work</button>
      </:actions>

      <form phx-change="update" class="grid gap-3">
        <input name="assignment[title]" value={@draft["title"]} placeholder="Work item" class="rounded border p-2" />
        <input name="assignment[target]" value={@draft["target"]} placeholder="Employee ID" class="rounded border p-2" />
      </form>

      <p :if={@flash_notice} class="text-sm text-emerald-700"><%= @flash_notice %></p>
    </ShellComponents.page>
    """
  end
end
