defmodule JidoBuilderWeb.Directives.BuilderLive do
  @moduledoc "Phase 2.8 — Directives Builder: lists all 11 directive types."
  use JidoBuilderWeb, :live_view

  @directive_types [
    %{name: "Emit", description: "Emit a signal to a target."},
    %{name: "Error", description: "Raise an error directive."},
    %{name: "Spawn", description: "Spawn a generic process."},
    %{name: "SpawnAgent", description: "Spawn a new agent process."},
    %{name: "AdoptChild", description: "Adopt an existing process as a child."},
    %{name: "StopChild", description: "Stop a child process."},
    %{name: "Schedule", description: "Schedule a delayed message."},
    %{name: "RunInstruction", description: "Run a one-off instruction."},
    %{name: "Stop", description: "Stop the current agent."},
    %{name: "Cron", description: "Schedule a recurring cron job."},
    %{name: "CronCancel", description: "Cancel a scheduled cron job."}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Directives Builder", directives: @directive_types)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p class="text-sm mb-4">Compose directives that agents execute in response to signals.</p>

    <ul class="space-y-2 text-sm">
      <li :for={d <- @directives} class="rounded border p-3">
        <span class="font-semibold"><%= d.name %></span>
        <p class="text-zinc-500 text-xs mt-1"><%= d.description %></p>
      </li>
    </ul>
    """
  end
end
