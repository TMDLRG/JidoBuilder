defmodule JidoBuilderWeb.GlossaryLive do
  @moduledoc "Phase 6 — Glossary of Jido terms."
  use JidoBuilderWeb, :live_view

  @terms [
    %{term: "Agent", definition: "A stateful, supervised process backed by Jido.Agent."},
    %{term: "Action", definition: "A pure function that transforms params and returns directives/state ops."},
    %{term: "Signal", definition: "A CloudEvent-compatible message routed to agents."},
    %{term: "Directive", definition: "An instruction for the runtime (emit, schedule, spawn, stop, cron)."},
    %{term: "StateOp", definition: "A state mutation (set, replace, delete_keys, set_path, delete_path)."},
    %{term: "Plugin", definition: "A composable behavior that adds routes, schedules, and lifecycle hooks."},
    %{term: "Sensor", definition: "An external data source that emits signals to agents."},
    %{term: "Pod", definition: "A topology of cooperating agent nodes with a coordination strategy."},
    %{term: "Strategy", definition: "Controls how an agent processes signals (Direct or FSM)."},
    %{term: "Template", definition: "A Builder-managed agent blueprint with routes, plugins, sensors, and state fields."}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Glossary", terms: @terms)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <dl class="space-y-3 text-sm mt-4">
      <div :for={entry <- @terms} class="border-b pb-2">
        <dt class="font-semibold"><%= entry.term %></dt>
        <dd class="text-zinc-600 text-xs mt-1"><%= entry.definition %></dd>
      </div>
    </dl>
    """
  end
end
