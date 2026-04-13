defmodule JidoBuilderWeb.WorkStyles.IndexLive do
  @moduledoc "Phase 2.7 — Work Styles picker: select a signal-processing strategy."
  use JidoBuilderWeb, :live_view

  @strategies [
    %{id: "direct", name: "Direct", description: "Immediately applies all operations in sequence."},
    %{id: "fsm", name: "FSM", description: "State-machine driven: transitions based on signal type."}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Work Styles", strategies: @strategies, selected: "direct")}
  end

  @impl true
  def handle_event("select_strategy", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected: id)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>
    <p class="text-sm mb-4">Select a Strategy for signal processing.</p>

    <ul class="space-y-3 text-sm">
      <li
        :for={s <- @strategies}
        phx-click="select_strategy"
        phx-value-id={s.id}
        class={"rounded border p-4 cursor-pointer transition-all #{if @selected == s.id, do: "border-green-500 bg-green-50 ring-2 ring-green-300", else: "hover:border-zinc-400"}"}
      >
        <div class="flex items-center justify-between">
          <span class="font-semibold">{s.name}</span>
          <span :if={@selected == s.id} class="text-green-600 text-xs font-medium px-2 py-0.5 bg-green-100 rounded">Active</span>
        </div>
        <p class="text-zinc-500 text-xs mt-1">{s.description}</p>
      </li>
    </ul>

    <p class="text-xs text-zinc-400 mt-4">
      Current strategy: <span class="font-mono font-semibold text-zinc-700">{@selected}</span>
    </p>
    """
  end
end
