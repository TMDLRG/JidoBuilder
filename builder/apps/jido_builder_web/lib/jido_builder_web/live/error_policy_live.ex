defmodule JidoBuilderWeb.ErrorPolicyLive do
  @moduledoc "Phase 6 — Error Policy editor."
  use JidoBuilderWeb, :live_view

  @policies [
    %{name: "stop_on_error", description: "Stop the agent immediately when an action fails."},
    %{name: "retry_once", description: "Retry the failed action once, then stop if it fails again."},
    %{name: "ignore", description: "Log the error and continue processing."},
    %{name: "escalate", description: "Notify parent agent and let it decide."}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Error Policy", policies: @policies)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p class="text-sm text-zinc-500 mb-4">Configure error handling behavior for agent execution.</p>
    <ul class="space-y-3 text-sm max-w-lg">
      <li :for={p <- @policies} class="border rounded p-3">
        <h3 class="font-semibold font-mono"><%= p.name %></h3>
        <p class="text-xs text-zinc-600 mt-1"><%= p.description %></p>
      </li>
    </ul>
    """
  end
end
