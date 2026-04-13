defmodule JidoBuilderWeb.MCP.Tools.HelpTool do
  @moduledoc "MCP tool: jido_help — documentation and guidance."

  alias JidoBuilderWeb.MCP.ToolRegistry

  def call(%{"action" => "guide"}, _ctx) do
    {:ok, """
    # JidoBuilder MCP Guide

    JidoBuilder is a commercial agent platform. Use these 13 tools to build, deploy, and operate agents:

    ## Core Tools
    1. **jido_agent** — Hire, list, stop, and dispatch signals to agents
    2. **jido_template** — Create and manage agent templates with routes
    3. **jido_workflow** — Build and execute multi-step workflows
    4. **jido_observe** — Query signal history, errors, and execution traces
    5. **jido_workspace** — Manage workspaces
    6. **jido_help** — Get help and documentation

    ## v2 Tools
    7. **jido_factory** — Compose templates, clone configs, version, deploy agent teams
    8. **jido_skill** — Browse and manage skill packs (action + prompt bundles)
    9. **jido_llm** — Configure LLM providers, models, and system prompts
    10. **jido_active_inference** — Create generative models, update beliefs, evaluate policies
    11. **jido_notebook** — Interactive code editor: create, run cells, export modules
    12. **jido_library** — Browse actions, skills, and solutions catalog
    13. **jido_solution** — Deploy pre-built multi-agent business solutions

    ## Quick Start
    1. Browse the library: `{tool: "jido_library", action: "browse_actions"}`
    2. Hire an agent: `{tool: "jido_agent", action: "hire", name: "my-agent"}`
    3. Dispatch a signal: `{tool: "jido_agent", action: "dispatch", id: "my-agent", signal_type: "ping"}`
    4. Try Active Inference: `{tool: "jido_active_inference", action: "presets"}`
    5. Run a notebook cell: `{tool: "jido_notebook", action: "run_cell", code: "1 + 1"}`
    6. Deploy a solution: `{tool: "jido_solution", action: "deploy", slug: "help_desk"}`
    """}
  end

  def call(%{"action" => "tool_help", "tool" => tool_name}, _ctx) do
    case ToolRegistry.get(tool_name) do
      nil -> {:error, "Unknown tool: #{tool_name}"}
      tool -> {:ok, "#{tool.name}: #{tool.description}\n\nInput schema: #{Jason.encode!(tool.input_schema, pretty: true)}"}
    end
  end

  def call(%{"action" => "glossary"}, _ctx) do
    {:ok, """
    ## JidoBuilder Glossary

    - **Agent** — A running Jido process that responds to signals
    - **Template** — A blueprint for creating agents with pre-configured routes
    - **Route** — Maps a signal type to an action module on a template
    - **Signal** — A message dispatched to an agent (type + payload)
    - **Action** — An executable module that processes signals (e.g., echo, HTTP request)
    - **Workflow** — A DAG of steps executed in topological order
    - **Workspace** — An isolated namespace for agents, templates, and workflows
    - **Correlation ID** — UUID that traces a dispatch through all execution logs
    - **Skill** — A named set of actions with a system prompt fragment for composable capabilities
    - **LLM Provider** — External language model service (Anthropic, OpenAI, or mock for testing)
    - **Active Inference** — Agent framework based on the Free Energy Principle for belief-driven decision-making
    - **Generative Model** — Probabilistic model (POMDP) encoding how observations are generated from hidden states
    - **Belief State** — An agent's posterior probability distribution over hidden states
    - **Free Energy** — Quantity minimized by Active Inference agents for perception and planning
    - **Policy** — A sequence of actions evaluated by expected free energy for planning
    - **Notebook** — Interactive code evaluation environment with persistent bindings
    - **Cell** — A single executable code block within a Notebook
    - **Factory** — Agent composition tool for merging templates, versioning, and team deployment
    - **Solution** — Pre-built multi-agent business package deployable as a coordinated team
    - **Template Library** — Browsable catalog of actions, skills, and solutions
    """}
  end

  def call(%{"action" => "examples"}, _ctx) do
    {:ok, """
    ## Example Workflows

    ### Hire and dispatch
    1. `{tool: "jido_agent", action: "hire", name: "worker-1"}`
    2. `{tool: "jido_agent", action: "dispatch", id: "worker-1", signal_type: "ping", payload: {message: "hello"}}`

    ### Template-based agent
    1. `{tool: "jido_template", action: "list"}` — find template IDs
    2. `{tool: "jido_agent", action: "hire", name: "smart-agent", template_id: 1}`
    3. `{tool: "jido_template", action: "list_routes", id: 1}` — see available signals

    ### Active Inference agent
    1. `{tool: "jido_active_inference", action: "presets"}` — list preset models
    2. `{tool: "jido_active_inference", action: "create_model", preset: "forager"}` — create model
    3. `{tool: "jido_active_inference", action: "evaluate", preset: "forager", observation: 0}` — update beliefs

    ### Deploy a business solution
    1. `{tool: "jido_solution", action: "list"}` — browse available solutions
    2. `{tool: "jido_solution", action: "deploy", slug: "help_desk"}` — deploy as agent team
    """}
  end

  def call(_, _), do: {:ok, "jido_help — Actions: guide, tool_help, glossary, examples"}
end
