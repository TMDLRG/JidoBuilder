defmodule JidoBuilderWeb.OnboardingLive do
  @moduledoc "Phase Final A.12 — onboarding walkthrough with actionable links."
  use JidoBuilderWeb, :live_view

  @steps [
    %{index: 1, title: "Step 1: Create a Workspace", body: "Workspaces isolate agents, templates, and secrets.", path: "/workspaces"},
    %{index: 2, title: "Step 2: Define a Template", body: "Templates are agent blueprints with routes, plugins, and state fields.", path: "/templates"},
    %{index: 3, title: "Step 3: Hire an Agent", body: "Start an agent instance from a template on the Roster page.", path: "/roster"},
    %{index: 4, title: "Step 4: Send a Signal", body: "Use the Assignments console to dispatch signals to running agents.", path: "/assignments/new"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Onboarding", step: 1, steps: @steps)}
  end

  @impl true
  def handle_event("next", _params, socket), do: {:noreply, assign(socket, step: min(socket.assigns.step + 1, 4))}

  def handle_event("prev", _params, socket), do: {:noreply, assign(socket, step: max(socket.assigns.step - 1, 1))}

  @impl true
  def render(assigns) do
    current = Enum.find(assigns.steps, &(&1.index == assigns.step))
    assigns = assign(assigns, :current, current)

    ~H"""
    <.page_header>Welcome to JidoBuilder</.page_header>

    <div class="mt-4 max-w-lg space-y-2">
      <h2 class="font-semibold text-sm"><%= @current.title %></h2>
      <p class="text-sm text-zinc-600"><%= @current.body %></p>
      <.link id={"step-#{@step}-do-it"} navigate={@current.path} class="inline-flex rounded border px-3 py-1 text-xs">Do it</.link>

      <div class="mt-4 flex gap-2 items-center">
        <button :if={@step > 1} phx-click="prev" class="border rounded px-3 py-1 text-xs">Back</button>
        <button :if={@step < 4} phx-click="next" class="rounded bg-zinc-900 px-3 py-1 text-white text-xs">Next</button>
        <span class="text-xs text-zinc-400 ml-2">Step <%= @step %> of 4</span>
      </div>
    </div>
    """
  end
end
