defmodule JidoBuilderWeb.WorkStyles.IndexLive do
  @moduledoc "Phase 2.7 — Work Styles picker: shows available strategy options."
  use JidoBuilderWeb, :live_view

  @strategies [
    %{name: "Direct", description: "Immediately applies all operations in sequence."},
    %{name: "FSM", description: "State-machine driven: transitions based on signal type."}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Work Styles", strategies: @strategies)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>
    <p class="text-sm mb-4">Select a Strategy for signal processing.</p>

    <ul class="space-y-3 text-sm">
      <li :for={s <- @strategies} class="rounded border p-3">
        <span class="font-semibold">{s.name}</span>
        <p class="text-zinc-500 text-xs mt-1">{s.description}</p>
      </li>
    </ul>
    """
  end
end
