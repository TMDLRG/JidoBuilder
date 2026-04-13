# JidoBuilder

> **A visual management console for building, configuring, and monitoring autonomous agents built on the [Jido](https://github.com/agentjido/jido) Elixir framework.**

JidoBuilder bridges the gap between the Jido SDK (for developers) and day-to-day agent operations. Developers define Actions; operators use Builder to assemble, deploy, and observe agents without writing code.

## Features

### Agent Management
- **Agent Roster** -- hire, stop, search, and filter agents with real-time status
- **Agent Detail** -- tabbed view with Overview, State Inspector, Signal History, and Actions
- **Agent Chat** -- conversational interface powered by LlmChat action with agentic tool-use loop
- **Agent Factory** -- deploy pre-built multi-agent solutions (Help Desk, DevOps Suite, etc.)

### LLM Agent System
- **Multi-provider support** -- Anthropic (Claude), OpenAI (GPT-4), and Mock provider
- **Agentic tool-use loop** -- LLM calls Jido Actions as tools, executes them, feeds results back
- **Tool Whitelist** -- per-template control over which of 75+ actions the LLM can invoke
- **LLM Agent Wizard** -- 4-step flow: identity, LLM config, tool selection, review & create
- **Conversation persistence** -- chat history saved to database with thread management

### Configuration
- **Templates** -- agent blueprints with routes, plugins, sensors, and state fields
- **Skills Manager** -- organize actions into skill categories (Research, Data Analysis, Code Review, etc.)
- **Directives Builder** -- compose 11 directive types with live Elixir struct preview
- **LLM Config** -- provider/model/temperature/system prompt + 70+ tool whitelist checkboxes
- **Identity Profiles** -- persona configurations for agents
- **Work Styles** -- selectable signal processing strategies (Direct, FSM)

### Build Tools
- **Block Library** -- browse and validate codegen block definitions
- **State Ops** -- compose and preview state operations with live JSON results
- **Hierarchy** -- manage parent-child agent relationships via pod topology
- **Pools** -- configure worker pool size and overflow limits
- **Threads** -- create named conversation contexts
- **Notebook** -- interactive Elixir code editor with persistent bindings

### Observability
- **Execution Monitor** -- real-time event timeline
- **Traces** -- signal trace log with type and correlation ID filters
- **Audit** -- chronological audit history with action filter and refresh
- **Metrics Dashboard** -- signals/errors per hour with live charts and refresh
- **Debug Console** -- toggle debug mode per-agent

### Admin
- **Settings** -- integrations and encrypted secrets management
- **Workspaces** -- multi-tenant workspace and partition management
- **Vault** -- agent snapshot hibernate/thaw with refresh and delete
- **Error Policy** -- per-template error handling (stop, retry, ignore, escalate) + circuit breakers
- **Template Library** -- 61 actions across 10 categories + 5 skill packs
- **Marketplace** -- browse plugins by category
- **Solutions** -- deploy business solution packages
- **Capabilities** -- discover and manage plugins

### Help
- **User Guide** -- comprehensive in-app documentation with sticky navigation
- **Glossary** -- 37 terms covering core Jido, Active Inference, and LLM concepts
- **Onboarding** -- 4-step wizard for new users

## Architecture

JidoBuilder is an Elixir umbrella application with four OTP apps:

| App | Purpose |
|-----|---------|
| `jido_builder_core` | Ecto schemas, database persistence, business logic |
| `jido_builder_runtime` | Agent lifecycle, signal dispatch, LLM client, action registry |
| `jido_builder_web` | Phoenix LiveView UI, MCP tools, router |
| `jido_builder_codegen` | Code generation utilities |

All three run in a single BEAM node. The Web layer uses Phoenix LiveView with real-time PubSub updates. The Runtime layer manages agent processes via the Jido framework. The Core layer handles persistence with Ecto and SQLite.

## Getting Started

### Prerequisites

- Elixir 1.18+
- Erlang/OTP 27+
- Node.js 18+ (for asset compilation)

### Setup

```bash
cd builder
mix deps.get
mix ecto.setup
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000). Default credentials: `op@test.com` / `password123`.

### Running Tests

```bash
cd builder
mix test
```

320 tests across all apps. Tests include unit tests, property-based tests, and LiveView interaction tests.

## Technology

- **[Jido](https://github.com/agentjido/jido)** -- autonomous agent framework for Elixir
- **[Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)** -- real-time server-rendered UI
- **[Ecto](https://hexdocs.pm/ecto)** + SQLite -- database persistence
- **[Tailwind CSS](https://tailwindcss.com)** -- utility-first styling

## License

JidoBuilder is licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE). You may use, modify, and distribute the software for any **non-commercial** purpose -- personal projects, education, research, non-profits, government use. **Commercial use requires a separate license.**

Contact [mpolzin@zimzap.com](mailto:mpolzin@zimzap.com) for commercial licensing.

### Acknowledgments

JidoBuilder is built on the [Jido agent framework](https://github.com/agentjido/jido) by [Agent Jido](https://github.com/agentjido) (Parker Selbert, Mike Hostetler), licensed under [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0). Jido code included in releases retains its Apache 2.0 license. Only original JidoBuilder code is covered by the PolyForm Noncommercial License.

## Author

**Michael Polzin** -- [mpolzin@zimzap.com](mailto:mpolzin@zimzap.com) | [LinkedIn](https://www.linkedin.com/in/mpolzin/)

Built using AI-assisted development with the [ORCHESTRATE Method](https://www.amazon.com/ORCHESTRATE-Prompting-Professional-AI-Outputs-ebook/dp/B0G2B9LG6V).
