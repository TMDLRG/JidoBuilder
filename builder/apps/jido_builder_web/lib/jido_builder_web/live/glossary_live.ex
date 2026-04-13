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
    %{term: "Template", definition: "A Builder-managed agent blueprint with routes, plugins, sensors, and state fields."},
    # -- v2 terms --
    %{term: "Active Inference", definition: "Agent framework based on the Free Energy Principle where agents minimize surprise by updating beliefs and selecting policies."},
    %{term: "Generative Model", definition: "A probabilistic model (POMDP) encoding how observations are generated from hidden states via likelihood, transition, and preference matrices."},
    %{term: "Free Energy", definition: "A quantity minimized by Active Inference agents — variational FE for perception, expected FE for planning."},
    %{term: "Belief State", definition: "An agent's posterior probability distribution over hidden states, updated via Bayesian inference on new observations."},
    %{term: "Policy", definition: "A sequence of action indices evaluated by expected free energy to balance exploration and exploitation."},
    %{term: "LLM Strategy", definition: "Agent execution strategy that uses a Large Language Model for reasoning, tool selection, and response generation."},
    %{term: "Skill", definition: "A named set of actions with a system prompt fragment — metadata for composing agent capabilities."},
    %{term: "Solution", definition: "A pre-composed multi-agent + workflow business package deployable as a coordinated team."},
    %{term: "Notebook", definition: "A LiveBook-style interactive code editor for building and testing agents with persistent bindings."},
    %{term: "Factory", definition: "A meta-system for creating, composing, versioning, and deploying agent templates."},
    %{term: "Markov Blanket", definition: "A statistical boundary separating an agent's internal states from external environment states."},
    %{term: "Expected Free Energy", definition: "A score for ranking action policies that decomposes into epistemic value (information gain) and pragmatic value (preference alignment)."},
    # -- LLM & conversation terms --
    %{term: "LlmChat", definition: "A Jido Action that implements a recursive agentic tool-use loop: calls the LLM, executes tool requests, feeds results back, and repeats until a text response is returned."},
    %{term: "Tool Whitelist", definition: "A per-template list of action slugs that controls which Jido Actions are exposed to the LLM as callable tools."},
    %{term: "Tool Bridge", definition: "The module that converts Jido Actions into LLM-compatible tool schemas and routes tool_use responses back to action execution."},
    %{term: "Conversation", definition: "A managed message history for multi-turn LLM interactions, with system prompt injection, token tracking, and automatic truncation."},
    %{term: "Conversation Persistence", definition: "Database-backed storage of chat messages grouped by conversation thread ID, enabling history reload across sessions."},
    %{term: "Memory Space", definition: "A named key-value store that agents can read from, write to, and search — enabling persistent knowledge across conversations."},
    %{term: "Workflow", definition: "A directed graph of steps (actions, emits, conditions, transforms) that defines a multi-step agent process."},
    %{term: "Signal Route", definition: "A mapping from a signal type to an action module within a template, determining how an agent handles each signal."},
    %{term: "Identity Profile", definition: "A persona configuration for an agent, including name, persona description, and capabilities list."},
    %{term: "Thread", definition: "A named conversation context within a template, used to scope chat history and memory operations."},
    %{term: "Resource Pool", definition: "A managed set of shared resources (connections, workers) that agents check out and return, with configurable size and overflow limits."},
    %{term: "Block", definition: "A reusable building block (action, agent, plugin, sensor, or strategy) that can be validated and composed into templates."},
    %{term: "FSM Strategy", definition: "A state-machine-driven signal processing strategy where transitions are determined by signal type."},
    %{term: "Direct Strategy", definition: "A signal processing strategy that immediately applies all operations in sequence without state-machine transitions."}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Glossary", terms: @terms)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>
    <dl class="space-y-3 text-sm mt-4">
      <div :for={entry <- @terms} class="border-b pb-2">
        <dt class="font-semibold">{entry.term}</dt>
        <dd class="text-zinc-600 text-xs mt-1">{entry.definition}</dd>
      </div>
    </dl>
    """
  end
end
