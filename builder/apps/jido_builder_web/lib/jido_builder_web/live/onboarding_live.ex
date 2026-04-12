defmodule JidoBuilderWeb.OnboardingLive do
  @moduledoc "Phase 6 — Onboarding walkthrough."
  use JidoBuilderWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Onboarding", step: 1)}
  end

  @impl true
  def handle_event("next", _params, socket) do
    {:noreply, assign(socket, step: min(socket.assigns.step + 1, 4))}
  end

  @impl true
  def handle_event("prev", _params, socket) do
    {:noreply, assign(socket, step: max(socket.assigns.step - 1, 1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Welcome to JidoBuilder</.page_header>

    <div class="mt-4 max-w-lg">
      <div :if={@step == 1} class="space-y-2">
        <h2 class="font-semibold text-sm">Step 1: Create a Workspace</h2>
        <p class="text-sm text-zinc-600">Workspaces isolate agents, templates, and secrets.</p>
      </div>
      <div :if={@step == 2} class="space-y-2">
        <h2 class="font-semibold text-sm">Step 2: Define a Template</h2>
        <p class="text-sm text-zinc-600">Templates are agent blueprints with routes, plugins, and state fields.</p>
      </div>
      <div :if={@step == 3} class="space-y-2">
        <h2 class="font-semibold text-sm">Step 3: Hire an Agent</h2>
        <p class="text-sm text-zinc-600">Start an agent instance from a template on the Roster page.</p>
      </div>
      <div :if={@step == 4} class="space-y-2">
        <h2 class="font-semibold text-sm">Step 4: Send a Signal</h2>
        <p class="text-sm text-zinc-600">Use the Assignments console to dispatch signals to running agents.</p>
      </div>

      <div class="mt-4 flex gap-2">
        <button :if={@step > 1} phx-click="prev" class="border rounded px-3 py-1 text-xs">Back</button>
        <button :if={@step < 4} phx-click="next" class="rounded bg-zinc-900 px-3 py-1 text-white text-xs">Next</button>
        <span class="text-xs text-zinc-400 ml-2">Step <%= @step %> of 4</span>
      </div>
    </div>
    """
  end
end
