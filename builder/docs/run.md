# Run Guide (Clean Clone -> Running App)

## 1) Prerequisites

- Elixir `~> 1.18`
- OTP `27+`
- Node.js 20+ (for frontend assets)

## 2) Clean clone and bootstrap

```bash
git clone <REPO_URL>
cd JidoBuilder/builder
mix setup
```

`mix setup` performs all first-run steps in order:

1. install Elixir deps (`mix deps.get`)
2. install frontend tooling (`mix assets_setup` in `apps/jido_builder_web`)
3. create database (`mix ecto.create`)
4. run migrations (`mix ecto.migrate`)
5. seed sample data (`mix run apps/jido_builder_core/priv/repo/seeds.exs`)

If you prefer running each command manually instead of `mix setup`, use:

```bash
mix deps.get
mix cmd --cd apps/jido_builder_web mix assets_setup
mix ecto.create
mix ecto.migrate
mix run apps/jido_builder_core/priv/repo/seeds.exs
```

## 3) Launch the server

```bash
mix phx.server
```

Open <http://127.0.0.1:4000>.

## 4) Smoke-test the first workflow (seeded data)

The seed file creates:

- workspace: `demo-workspace`
- workflow: `First Workflow`
- steps:
  - `Collect Input`
  - `Run Runtime`
  - `Publish Output`

Smoke-test checklist:

1. Open <http://127.0.0.1:4000/workflows>.
2. Confirm **Workflow Builder** is visible.
3. Confirm **Workflow Execution Stream** is visible.
4. Open <http://127.0.0.1:4000/agents/demo-1>.
5. Confirm **Viewing agent demo-1** and **Agent Event Stream** are visible.

## 5) Quality and test commands

```bash
mix quality
mix test
```

`mix quality` runs:

- formatting check
- compile with warnings as errors
- credo strict checks
- dialyzer

## 6) Optional integrations (offline-safe defaults)

By default, optional integrations are disabled to keep local development fully offline-safe.

### Redis (optional)

- `JIDO_BUILDER_REDIS_ENABLED=false` (default)
- `JIDO_BUILDER_REDIS_URL=redis://127.0.0.1:6379/0` (used only if enabled)

Enable only when a Redis instance is available:

```bash
export JIDO_BUILDER_REDIS_ENABLED=true
export JIDO_BUILDER_REDIS_URL=redis://127.0.0.1:6379/0
```

### LLM providers (optional)

- `JIDO_BUILDER_LLM_ENABLED=false` (default)
- `JIDO_BUILDER_LLM_PROVIDER=none` (default)
- `JIDO_BUILDER_LLM_API_BASE=""` (default)

Enable only when you intentionally configure an external provider:

```bash
export JIDO_BUILDER_LLM_ENABLED=true
export JIDO_BUILDER_LLM_PROVIDER=openai   # or anthropic/other provider labels
export JIDO_BUILDER_LLM_API_BASE=https://api.openai.com/v1
```

Keep these unset in offline/local-only runs.
