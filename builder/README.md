# JidoBuilder

A no-code Phoenix LiveView UI for the [Jido](https://github.com/agentjido/jido) autonomous agent framework. Build, manage, and orchestrate distributed agent systems through a web interface — no Elixir code required.

## Features

- **Agent Roster** — Hire, monitor, and stop Jido agents from the browser
- **Signal Dispatch** — Send signals to running agents with custom payloads
- **Cron Schedules** — Create and cancel recurring agent triggers
- **Workflow Builder** — Visual DAG editor for multi-step agent workflows
- **Pod Orchestration** — Group agents into pods with routing strategies
- **Template Library** — Define reusable agent templates with plugins, sensors, routes, and state fields
- **Code Generation** — Generate standalone Elixir modules from block definitions (action, agent, plugin, sensor, strategy)
- **Directive Composer** — Build any of 11 directive types (emit, spawn, cron, stop, etc.)
- **Skills Catalog** — Browse all registered Jido actions with search/filter
- **State Operations** — Preview all 5 state op types (set, replace, delete_keys, set_path, delete_path)
- **Observability** — Debug panel, signal traces, audit trail with actor attribution
- **Secrets Management** — Encrypted secret storage with redacted display
- **Auth** — PBKDF2 password authentication with session management

## Architecture

Umbrella application with 5 apps:

| App | Purpose |
|-----|---------|
| `jido_builder_core` | SQLite3 Ecto schemas, persistence, audit, secrets |
| `jido_builder_runtime` | Jido adapter layer — hiring, signals, directives, telemetry |
| `jido_builder_codegen` | Elixir source generation and compilation pipeline |
| `jido_builder_generated` | Output destination for generated modules |
| `jido_builder_web` | Phoenix LiveView UI (34 authenticated routes) |

## Quick Start

```bash
# Clone and setup
git clone https://github.com/TMDLRG/JidoBuilder.git
cd JidoBuilder/builder

# Install dependencies
mix deps.get

# Create and migrate database
mix ecto.create
mix ecto.migrate

# Create an operator account
mix jido_builder.create_user --email operator@example.com --password changeme123

# Seed demo data (optional)
mix run apps/jido_builder_core/priv/repo/seeds.exs

# Build assets
mix assets.deploy  # or: mix tailwind jido_builder_web && mix esbuild jido_builder_web

# Start the server
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000) and sign in.

## Routes

### Core Agent Operations
| Route | Page | Description |
|-------|------|-------------|
| `/` | Dashboard | Running agent count, workspace activity |
| `/roster` | Roster | Hire/stop agents, view running workers |
| `/agents/:id` | Agent Detail | Per-agent state and metadata |
| `/assignments/new` | Signal Dispatch | Send signals to running agents |
| `/schedules` | Schedules | Create/cancel cron triggers |
| `/workflows` | Workflow Builder | Visual DAG editor with D3 |
| `/state-ops` | State Ops | Preview all 5 state operation types |

### Configuration
| Route | Page | Description |
|-------|------|-------------|
| `/templates` | Templates | CRUD for agent templates |
| `/capability-packs` | Plugins | Discover and configure Jido plugins |
| `/watchers` | Sensors | Discover and configure Jido sensors |
| `/directives` | Directives | Compose any of 11 directive types |
| `/skills` | Skills Catalog | Browse registered actions with search |
| `/error-policy` | Error Policy | Set per-template error handling strategy |
| `/pools` | Worker Pools | Configure pool sizes and overflow |

### Orchestration
| Route | Page | Description |
|-------|------|-------------|
| `/teams` | Teams/Pods | Create pod topologies with strategies |
| `/hierarchy` | Hierarchy | Add agents to pods, view topology tree |
| `/orphans` | Orphan Agents | Find unattached agents, adopt into pods |
| `/workspaces` | Workspaces | Multi-tenant workspace management |

### Code Generation
| Route | Page | Description |
|-------|------|-------------|
| `/blocks` | Block Library | Validate codegen block definitions |
| `/editor/:type` | Block Editor | Edit action/agent/plugin/sensor/strategy |
| `/ejector` | Ejector | Export blocks as standalone Elixir modules |

### Observability & Admin
| Route | Page | Description |
|-------|------|-------------|
| `/debug` | Debug | Toggle debug mode, per-agent status |
| `/traces` | Traces | Filter and inspect signal traces |
| `/audit` | Audit History | Full audit trail with actor + timestamp |
| `/settings` | Settings | Integrations and encrypted secrets |
| `/vault` | Vault | Agent state snapshots |

### Context & Onboarding
| Route | Page | Description |
|-------|------|-------------|
| `/threads` | Threads | Thread entries for agent context |
| `/memory` | Memory Spaces | Named memory space configuration |
| `/identity` | Identity | Agent identity profiles (name, persona, capabilities) |
| `/onboarding` | Onboarding | 4-step guided setup walkthrough |

## API Endpoints (No Auth)

| Endpoint | Description |
|----------|-------------|
| `GET /healthz` | Liveness check (200 OK) |
| `GET /readyz` | Readiness check |
| `GET /metrics` | Prometheus metrics |

## Docker

```bash
cd builder
docker build -f Dockerfile -t jido-builder:latest ..
docker run -p 4000:4000 \
  -e SECRET_KEY_BASE=$(mix phx.gen.secret) \
  -e DATABASE_PATH=/var/lib/jido_builder/jido_builder.db \
  jido-builder:latest
```

## Testing

```bash
cd builder
mix test        # 109 tests, 0 failures
mix credo       # Static analysis
mix dialyzer    # Type checking
```

## Database

SQLite3 in WAL mode. Backup script:

```bash
./infra/backup.sh jido_builder_dev.db /path/to/backup.db
sqlite3 /path/to/backup.db "PRAGMA integrity_check;"
```

## Tech Stack

- **Elixir 1.19** + **Erlang/OTP 28**
- **Phoenix 1.7** + **Phoenix LiveView 1.1**
- **SQLite3** via Ecto (exqlite)
- **Tailwind CSS v4** for styling
- **D3.js** for workflow DAG visualization
- **Jido** autonomous agent framework

## Acknowledgments

JidoBuilder is built for and integrates with the
[Jido](https://github.com/agentjido/jido) autonomous agent framework,
created by [Mike Hostetler](https://github.com/agentjido) and the Jido
community. Jido is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

Releases of JidoBuilder may include code from the Jido project. See the
[NOTICE](../NOTICE) file for full attribution details.

## License

**PolyForm Noncommercial License 1.0.0** — see [LICENSE](LICENSE) for details.

This software is free for non-commercial use, including personal projects,
education, research, and use by non-profit organizations. **Commercial use
is not permitted** without a separate license agreement.

If you use or redistribute JidoBuilder, you must:
- Include a copy of the [LICENSE](LICENSE)
- Preserve the `Required Notice` lines from the license
- Preserve the [NOTICE](../NOTICE) file with Jido attribution

For commercial licensing inquiries, please open an issue or contact the
maintainers.
