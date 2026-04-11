# Jido Builder — Umbrella Implementation Plan for GPT Codex

**Mission:** Engineer, design, code, build, test, and verify a complete
no-code UI for Jido that exposes **every capability the Jido framework
provides in code** to a non-developer through a plain-language,
HR-flavored operational interface — and actually runs real Jido agents,
emits real signals, executes real directives, persists real state, and
streams real-time results back to the UI.

> **Non-negotiable scope rule:** If a Jido creator can do it in Elixir
> using the public API or documented guides, the Builder UI must do it for
> a layman — either through data-driven configuration or through visually
> composed code generation, never by requiring the user to write Elixir.

This plan supersedes all prior drafts. It is grounded in the actual Jido
repo at this workspace root.

---

## 0. Ground Truth — What You Are Actually Working With

### 0.1 The repo is a library, not an application

This workspace is the source of the `jido` Hex package (`mix.exs`,
`app: :jido`). It has **no Phoenix endpoint, no Ecto repo, no LiveView,
no frontend**. Treat `lib/jido/`, `lib/jido.ex`, `mix.exs`, `guides/`,
and `test/` as **read-only upstream**. All Builder code goes under
`builder/` as a self-contained umbrella that depends on the upstream
library via a path dependency.

### 0.2 Umbrella layout (required)

```
JidoBuilder/                        <-- repo root (upstream Jido library)
├── lib/jido/                       <-- read-only upstream
├── lib/jido.ex                     <-- read-only upstream
├── mix.exs                         <-- read-only upstream
├── guides/                         <-- read-only reference
├── test/                           <-- read-only upstream
├── BUILDER_PLAN.md                 <-- this file
└── builder/                        <-- NEW: umbrella root
    ├── mix.exs                     <-- umbrella mix, apps_path: "apps"
    ├── config/
    │   ├── config.exs
    │   ├── dev.exs
    │   ├── test.exs
    │   └── prod.exs
    └── apps/
        ├── jido_builder_core/      # Ecto schemas, contexts, audit, secrets
        ├── jido_builder_runtime/   # Jido wrapper, DynamicAgent, Dispatch,
        │                           # telemetry bridge, sensor host
        ├── jido_builder_codegen/   # Elixir source generation + compile
        ├── jido_builder_generated/ # Destination app for user-generated modules
        └── jido_builder_web/       # Phoenix LiveView UI
```

Each app that needs the upstream Jido library declares it via
`{:jido, path: "../../..", override: true}` (three `..` from an app's
own `mix.exs` to the repo root). The `jido_signal` and `jido_action`
packages come from Hex alongside it.

**Why an umbrella:** the Builder has distinct concerns — persistence,
runtime adapters, code generation, and web UI — that each have different
dependency footprints, test surfaces, and compile cycles. Putting them in
one monolithic app makes the test matrix slow and the dependency graph
muddled. The umbrella makes ownership boundaries explicit.

### 0.3 Jido's actual public API surface (extracted from repo)

These are the functions and modules Codex will call. Do not invent others.

**Top-level lifecycle (`lib/jido.ex`):**

| Function | Purpose |
|---|---|
| `MyApp.Jido.start_agent/2` | Start an agent under supervision |
| `MyApp.Jido.stop_agent/1,2` | Terminate a running agent |
| `MyApp.Jido.whereis/1,2` | Look up running agent pid by ID |
| `MyApp.Jido.list_agents/0,1` | List `[{id, pid}]` tuples |
| `MyApp.Jido.agent_count/0,1` | Running agent count |
| `MyApp.Jido.hibernate/1,2` | Persist agent to storage |
| `MyApp.Jido.thaw/2,3` | Restore agent from storage |
| `MyApp.Jido.debug/0,1,2` | Toggle debug level per instance |
| `MyApp.Jido.recent/1,2` | Recent debug events from agent ring buffer |
| `MyApp.Jido.debug_status/0` | Current debug state |
| `Jido.parent_binding/2,3` | Live parent/child relationship lookup |

**AgentServer (`lib/jido/agent_server.ex`):**

| Function | Purpose |
|---|---|
| `Jido.AgentServer.call/2,3` | Synchronous signal send |
| `Jido.AgentServer.cast/2` | Async signal send |
| `Jido.AgentServer.state/1` | Get current agent struct |
| `Jido.AgentServer.recent_events/2` | Debug ring-buffer events |
| `Jido.AgentServer.set_debug/2` | Toggle per-agent debug |

**Discovery (`lib/jido/discovery.ex`):**

| Function | Purpose |
|---|---|
| `Jido.Discovery.list_actions/1` | Browse registered actions |
| `Jido.Discovery.list_agents/1` | Browse registered agent modules |
| `Jido.Discovery.list_sensors/1` | Browse registered sensors |
| `Jido.Discovery.list_plugins/1` | Browse registered plugins |
| `Jido.Discovery.list_demos/1` | Browse demos |
| `Jido.Discovery.get_action_by_slug/1` (+ other primitive types) | Stable lookups |
| `Jido.Discovery.refresh/0` | Rebuild catalog after new modules loaded |
| `Jido.Discovery.catalog/0` | Full catalog snapshot |
| `Jido.Discovery.init_async/0` | Non-blocking startup |

**Signals (`jido_signal` package):**

| Function | Purpose |
|---|---|
| `Jido.Signal.new!/2,3` | Build a CloudEvents-style envelope |

**Directive types (`lib/jido/agent/directive.ex`):**

- `Jido.Agent.Directive.Error`
- `Jido.Agent.Directive.Emit`
- `Jido.Agent.Directive.Spawn`
- `Jido.Agent.Directive.SpawnAgent`
- `Jido.Agent.Directive.AdoptChild`
- `Jido.Agent.Directive.StopChild`
- `Jido.Agent.Directive.Schedule`
- `Jido.Agent.Directive.RunInstruction`
- `Jido.Agent.Directive.Stop`
- `Jido.Agent.Directive.Cron` (`lib/jido/agent/directive/cron.ex`)
- `Jido.Agent.Directive.CronCancel` (`lib/jido/agent/directive/cron_cancel.ex`)

Plus the helper `Jido.Agent.Directive.emit/1,2`,
`emit_to_pid/2`, `emit_to_parent/2,3`, `spawn/1`, `spawn_agent/2,3`,
`adopt_child/2,3`, `stop_child/1,2`, `stop/0,1`, `schedule/2`,
`cron/2,3`, `cron_cancel/1`, `run_instruction/2`, `error/1`.

**State operations (`lib/jido/agent/state_op.ex`):**

- `Jido.Agent.StateOp.SetState`
- `Jido.Agent.StateOp.ReplaceState`
- `Jido.Agent.StateOp.DeleteKeys`
- `Jido.Agent.StateOp.SetPath`
- `Jido.Agent.StateOp.DeletePath`

**Built-in actions (`lib/jido/actions/`):**

- `Jido.Actions.Control` — `Broadcast`, `Cancel`, `Forward`, `Noop`, `Reply`
- `Jido.Actions.Lifecycle` — `NotifyParent`, `NotifyPid`, `SpawnChild`,
  `StopChild`, `StopSelf`
- `Jido.Actions.Scheduling` — `CancelCron`, `ScheduleCron`, `ScheduleSignal`,
  `ScheduleTimeout`
- `Jido.Actions.Status` — `MarkCompleted`, `MarkFailed`, `MarkIdle`,
  `MarkWorking`, `SetStatus`

**Strategies (`lib/jido/agent/strategy/`):**

- `Jido.Agent.Strategy.Direct` — straight-through execution
- `Jido.Agent.Strategy.FSM` — state-machine execution

**Pods (`lib/jido/pod.ex`, `lib/jido/pod/`):**

- `Jido.Pod` — behavior for defining pods
- `Jido.Pod.Topology` — pure data topology
- `Jido.Pod.get/2,3`, `ensure_node/3`, `mutate/3`
- Pod actions: `Jido.Pod.Actions.Mutate`, `Jido.Pod.Actions.Evolve`
- `Jido.Agent.InstanceManager` — keyed durable lifecycle registry

**Plugins (`lib/jido/plugin/`):**

- `Jido.Plugin` — behavior for defining plugins
- `Jido.Plugin.Spec`, `Config`, `Manifest`, `Requirements`, `Routes`,
  `Schedules`, `Instance`

**Sensors (`lib/jido/sensor*`, `lib/jido/sensors/`):**

- `Jido.Sensor` — behavior
- `Jido.Sensor.Runtime`, `Jido.Sensor.Spec`
- `Jido.Sensors.Heartbeat`, `Jido.Sensors.Bus`

**Storage (`lib/jido/storage/`):**

- `Jido.Storage.ETS` (default in-memory)
- `Jido.Storage.File` (file-backed)
- `Jido.Storage.Redis` (redis-backed)
- `Jido.Persist` (persistence API)
- `Jido.Agent.InstanceManager` — keyed lifecycle

**Threads (`lib/jido/thread/`):**

- `Jido.Thread`, `Jido.Thread.Agent`, `Jido.Thread.Entry`,
  `Jido.Thread.Plugin`, `Jido.Thread.Store`
- Adapters: `Jido.Thread.Store.Adapters.InMemory`,
  `Jido.Thread.Store.Adapters.JournalBacked`

**Memory (`lib/jido/memory/`):**

- `Jido.Memory`, `Jido.Memory.Agent`, `Jido.Memory.Plugin`,
  `Jido.Memory.Space`

**Identity (`lib/jido/identity/`):**

- `Jido.Identity`, `Jido.Identity.Agent`, `Jido.Identity.Plugin`,
  `Jido.Identity.Profile`

**Observability (`lib/jido/observe.ex`, `lib/jido/observe/`,
`lib/jido/tracing/`):**

- `Jido.Observe`, `Jido.Observe.Config`, `Jido.Observe.EventContract`
- `Jido.Tracing.Context`, `Jido.Tracing.Trace`
- Telemetry events under `[:jido, :agent, :cmd, ...]` and
  `[:jido, :agent_server, :signal, ...]`

**Scheduling (`lib/jido/scheduler/`):**

- `Jido.Scheduler`, `Jido.Scheduler.Job`

**Awaits (`lib/jido/await.ex`):**

- `Jido.Await.completion/2,3`, `child/3,4`, `all/2,3`, `any/2,3`,
  `alive?/1`, `cancel/1,2`, `get_children/1`, `get_child/2`

**Worker pools (`lib/jido/agent/worker_pool.ex`):**

- `Jido.Agent.WorkerPool`

**Debug (`lib/jido/debug.ex`):**

- `Jido.Debug` with levels `:off`, `:on`, `:verbose`

**Igniter helpers (`lib/jido/igniter/`):**

- `Jido.Igniter.Helpers`, `Jido.Igniter.Templates` — scaffolding
  templates the Builder's codegen app can reuse for Elixir source
  generation.

Telemetry events (from `guides/observability.md`) the Builder subscribes
to for live UI updates:

- `[:jido, :agent, :cmd, :start | :stop | :exception]`
- `[:jido, :agent_server, :signal, :start | :stop | :exception]`
- plus all Jido-emitted spans under `[:jido, :action, ...]` when
  `telemetry.log_args: :full` is set.

### 0.4 The no-code scope question — dual-path strategy

A plain "data-driven agent" covers roughly 80% of what a Jido creator
does. The remaining 20% — custom strategies, custom plugins, custom
sensors, custom signal handlers, arbitrary action business logic — are
Elixir behaviors that ultimately must exist as compiled modules.

To honor the "everything a creator can do" requirement, the Builder ships
**two complementary paths**, and the UI transparently picks the right one
per capability.

#### Path A — Data-driven interpretation (runtime config)

A small set of *generic* Jido modules written once, which read their
behavior from database-stored config at runtime. Nothing is compiled
per-user.

- `JidoBuilder.Runtime.DynamicAgent` — schema slots are open
  (`{:map, ...}`); signal routes resolved at mount via
  `on_before_cmd/2`; state operations applied by a data-driven strategy.
- `JidoBuilder.Runtime.DynamicPod` — canonical topology loaded from DB.
- `JidoBuilder.Runtime.DynamicPlugin` — data-driven plugin that mounts
  template-specified action routes.
- `JidoBuilder.Runtime.DynamicSensor` — parametric sensor that emits
  signals on a schedule or condition read from the DB.
- `JidoBuilder.Runtime.Dispatch` — generic action that looks up an
  allow-listed action slug via `Jido.Discovery.get_action_by_slug/1`
  and runs it through `Jido.Exec.run/3`.
- `JidoBuilder.Runtime.DirectiveEmitter` — generic action that emits
  any of the 11 directive types from config input (e.g., user picks
  "Schedule" in the UI, the Builder stores `{delay_ms, message}`, and
  this action returns `[Directive.schedule(delay, message)]`).
- `JidoBuilder.Runtime.StateOpAction` — generic action that applies
  any of the 5 state operations from config.

This path covers:

- Agent state schemas (stored as typed field definitions)
- Signal routing (stored as `{pattern, action_slug}` rows)
- All 11 directives (user picks one, provides data)
- All 5 state ops
- Strategy choice between Direct and FSM (FSM transitions stored as DB
  rows the data-driven strategy interprets)
- Plugin inclusion from the discovered catalog
- Sensor configuration (heartbeat intervals, bus filters)
- Pod topologies (eager/lazy members, nested pods)
- Persistence selection (ETS/File/Redis per template)
- Worker pool sizing
- Scheduling (declarative cron + dynamic cron directives)
- Debug level per agent
- Partition assignment for multi-tenancy
- Memory spaces, thread journaling, identity profiles (as config rows
  the generic plugins mount)

#### Path B — Codegen + hot compile (for the 20%)

For capabilities that *require* a custom Elixir module — custom strategy
behavior callbacks, custom sensor logic beyond parameters, custom plugin
lifecycle hooks, custom action `run/2` logic that is not expressible as
a parameterized built-in — the Builder provides a **structured visual
editor** that writes Elixir source files into
`builder/apps/jido_builder_generated/lib/...`, compiles them at runtime
via `Code.compile_file/1` or `Kernel.ParallelCompiler.compile/1`, and
registers them with `Jido.Discovery.refresh/0`.

The user never sees or types Elixir. They see a block-based editor
driven by forms ("On signal X do Y, then if Z do W"). The codegen app
renders these blocks into EEx templates and produces real `.ex` files.

The generated app (`jido_builder_generated`) exists solely as the
destination for these files. It is compiled as part of the umbrella and
picked up by Discovery on refresh. The Builder ships with a curated
block library that maps cleanly to Jido primitives — `emit_signal`,
`schedule`, `spawn_agent`, `stop_child`, `set_state`, `delete_path`,
`call_llm` (via `jido_ai` if the user wired it), `http_request`,
`wait_for`, `branch_if`, `loop_while`, etc. Each block has a fixed,
audited Elixir template. The block editor composes templates; it never
evaluates arbitrary user strings.

This path covers:

- Custom actions with branching/looping logic
- Custom sensors beyond parametric types
- Custom plugins that declare new routes and state keys
- Custom FSM transition tables with guards/effects
- Custom strategies (expert mode — offers a scaffold for the
  `Jido.Agent.Strategy` behavior and lets the user fill in predefined
  blocks for `handle_action/3`, `handle_directive/3`, etc.)
- Export-to-code: the "Eject" button that renders the user's template
  as a clean standalone Elixir module for handoff to a dev team.

**Security stance:** the codegen path only writes files into the
`jido_builder_generated` app directory, never into `lib/jido/` or any
other app. Compilation is sandboxed to the generated app. User input is
never concatenated into Elixir source — it is passed as data to EEx
templates with strict escaping. Only the Builder's own curated block
library is written to disk. There is no "paste Elixir code" field.

**Runtime stance:** `Code.compile_file/1` loads the compiled module into
the running VM. The Discovery catalog refreshes. The user's new
capability is immediately available to hire, task, and inspect. On app
restart, the files are picked up naturally by `mix compile`.

---

## 1. Phase 1 — Discover and Map (pass 1 validation)

**Input artifacts to read before writing code:**

Upstream guides under `guides/`:

- `core-loop.md`, `agents.md`, `actions.md`, `signals.md`, `directives.md`,
- `state-ops.md`, `plugins.md`, `strategies.md`, `runtime.md`,
- `runtime-patterns.md`, `phoenix-integration.md`, `discovery.md`,
- `observability.md`, `observability-intro.md`, `debugging.md`,
- `storage.md`, `pods.md`, `multi-tenancy.md`, `orchestration.md`,
- `await.md`, `scheduling.md`, `sensors.md`, `your-first-sensor.md`,
- `your-first-plugin.md`, `custom-strategies.md`, `worker-pools.md`,
- `orphans.md`, `errors.md`, `testing.md`, `configuration.md`,
- `fsm-strategy.livemd`, `ash-integration.md`, `migration.md`.

Upstream source:

- `lib/jido.ex` — top-level API
- `lib/jido/agent.ex` — agent behavior
- `lib/jido/agent_server.ex` — runtime API
- `lib/jido/agent_server/signal_router.ex` — routing semantics
- `lib/jido/agent/directive.ex` — all 9 core directives
- `lib/jido/agent/directive/cron.ex`, `cron_cancel.ex` — cron directives
- `lib/jido/agent/state_op.ex` — state operations
- `lib/jido/agent/strategy.ex` + `strategy/{direct,fsm}.ex` — strategies
- `lib/jido/pod.ex`, `lib/jido/pod/topology.ex` — pod topology
- `lib/jido/plugin.ex`, `lib/jido/plugin/spec.ex` — plugin behavior
- `lib/jido/sensor.ex`, `lib/jido/sensor/spec.ex` — sensor behavior
- `lib/jido/storage.ex` + `storage/{ets,file,redis}.ex` — adapters
- `lib/jido/thread/store.ex` — thread journaling
- `lib/jido/memory/space.ex` — memory spaces
- `lib/jido/identity/profile.ex` — identity profiles
- `lib/jido/observe.ex`, `lib/jido/tracing/context.ex` — telemetry/tracing
- `lib/jido/await.ex` — coordination
- `lib/jido/discovery.ex` — catalog
- `lib/jido/debug.ex` — debug API
- `lib/jido/agent/worker_pool.ex` — pools
- `lib/jido/scheduler.ex`, `lib/jido/scheduler/job.ex` — scheduling
- `lib/jido/igniter/templates.ex` — template helpers to reuse in codegen
- `deep-research-report.md` — project-specific research context

**Deliverable:** `builder/docs/capability_map.md` — an exhaustive table
where every row is one Jido capability from the list in Section 0.3,
mapped to:

1. UI screen(s) that expose it
2. Path (A data-driven, B codegen, or hybrid)
3. Implementation status (planned, in-progress, done, deferred)
4. Confidence rating (1–5)
5. Notes / caveats

**Every capability in Section 0.3 must appear in that table.** If a
capability cannot ship in MVP, the row must state the explicit blocker
and the deferred-backlog ID.

---

## 2. Phase 2 — Architecture (decisions, not exploration)

### 2.1 Stack (already decided — do not re-litigate)

- **Phoenix LiveView** (`guides/phoenix-integration.md` is the template)
- **Ecto + SQLite** for local persistence (`ecto_sqlite3`) — keeps
  local-only install to one command
- **Cloak.Ecto** for encrypted secrets
- **Phoenix.PubSub** as the real-time transport (already a Jido dep,
  see `mix.exs` `{:phoenix_pubsub, "~> 2.1"}`)
- **Umbrella** with four functional apps + one generated-modules app
- **Playwright** for end-to-end tests (Phoenix-friendly, headless)
- **No React, no Next.js, no hybrid frontend.**

### 2.2 Process topology

```
JidoBuilder.Umbrella supervision tree (started by jido_builder_web):

├── JidoBuilderCore.Repo (Ecto SQLite)
├── {Phoenix.PubSub, name: JidoBuilder.PubSub}
├── JidoBuilderCore.Vault              # Cloak vault for secrets
├── JidoBuilderRuntime.Jido            # use Jido, otp_app: :jido_builder
│   ├── Task.Supervisor
│   ├── Registry
│   ├── RuntimeStore (ETS)
│   ├── DynamicSupervisor (agent children)
│   └── WorkerPools (config-driven)
├── JidoBuilderRuntime.InstanceManagers  # per-template keyed managers
├── JidoBuilderRuntime.SensorHost        # hosts running Jido sensors
├── JidoBuilderRuntime.TelemetryHandler  # [:jido, ...] → PubSub + DB
├── JidoBuilderRuntime.DebugEventTap     # pipes AgentServer.recent_events/2
├── JidoBuilderCore.AuditLog.Writer      # persisted audit stream
├── JidoBuilderCodegen.CompileQueue      # serialized compile requests
├── JidoBuilderCodegen.DiscoveryRefresh  # post-compile Discovery refresh
└── JidoBuilderWeb.Endpoint
```

### 2.3 Domain model (Ecto schemas, comprehensive)

`jido_builder_core` owns all schemas:

| Table | Purpose |
|---|---|
| `workspaces` | Top-level tenancy bucket (maps to Jido partition) |
| `agent_templates` | Job descriptions: name, persona, description, schema_fields, default_state, strategy_type, fsm_spec_id, plugin_slugs, allowed_action_slugs, signal_routes, schedules, debug_level, storage_adapter, worker_pool_key, generated_module |
| `agent_schema_fields` | Typed field definitions (name, type, default, required) |
| `agent_instances` | Hired agents: template_id, display_name, status, partition, jido_agent_id, parent_instance_id, last_hibernate_at, parent_death_policy |
| `plugins` | Plugin records — catalog entries + user-defined plugins with routes, actions, schedules |
| `plugin_routes` | `(plugin_id, pattern, action_slug)` rows |
| `plugin_schedules` | `(plugin_id, cron_expr, message, job_id)` rows |
| `actions_catalog` | Cached view of `Jido.Discovery.list_actions/1` + generated actions |
| `generated_actions` | User-composed actions with block tree, file path, compiled_at |
| `generated_sensors` | User-composed sensors with block tree, file path |
| `generated_plugins` | User-composed plugins with manifest and blocks |
| `generated_strategies` | User-composed strategies with transition tables |
| `fsm_specs` | State machine specs: states, events, guards, effects |
| `pods` | Teams: name, purpose, topology (JSON), parent_pod_id |
| `pod_members` | `(pod_id, role_key, agent_template_id, activation, manager_key)` |
| `workflows` | Playbooks: trigger, steps, branches, timeouts |
| `workflow_steps` | Ordered steps with input/output mapping |
| `assignments` | Tasks: target_type, target_id, signal_type, payload, status, result |
| `signals_log` | Persisted signal envelopes with direction and correlation |
| `directives_log` | Directives emitted per cmd (type, payload, result) |
| `state_ops_log` | State ops applied per cmd |
| `audit_events` | Who-did-what log with before/after diffs |
| `snapshots` | Hibernated state references (adapter, key, metadata, template_id) |
| `secrets` | Encrypted key/value (cloak_ecto) for integrations |
| `integrations` | Provider config rows (LLM providers, storage, etc.) |
| `identities` | Identity profiles (maps to `Jido.Identity.Profile`) |
| `memory_spaces` | Memory spaces (maps to `Jido.Memory.Space`) |
| `threads` | Thread records mapped to `Jido.Thread` stores |
| `sensors` | Configured sensors: type, parameters, enabled, owner_template_id |
| `worker_pools` | `(key, size, max_overflow, template_id)` |
| `schedules` | Declarative cron schedules per template/plugin |
| `telemetry_subscriptions` | Event → topic routing rows |
| `traces` | Stored traces for trace viewer (tracing/context) |

### 2.4 Umbrella app boundaries and dependency graph

```
jido_builder_core  (depends on: ecto, ecto_sqlite3, cloak, cloak_ecto,
                                jason, phoenix_pubsub)
       ▲
       │
       ├── jido_builder_runtime  (depends on: jido_builder_core, jido [path],
       │                                      jido_signal, jido_action,
       │                                      telemetry)
       │              ▲
       │              │
       │   ┌──────────┴──────────┐
       │   │                     │
jido_builder_codegen             jido_builder_generated
(depends on: jido_builder_core,  (depends on: jido [path], jido_action,
             eex)                              jido_builder_runtime)
       │                     │
       └──────────┬──────────┘
                  │
        jido_builder_web  (depends on: phoenix, phoenix_live_view,
                                       jido_builder_core,
                                       jido_builder_runtime,
                                       jido_builder_codegen)
```

### 2.5 Context modules inside each app

`jido_builder_core/lib/jido_builder_core/`:

- `workspaces/` — tenancy + partitions
- `templates/` — template CRUD, field editor, route editor
- `roster/` — hire/fire/pause/resume orchestration (calls runtime app)
- `assignments/` — compose + track
- `pods/` — pod CRUD
- `plugins/` — plugin CRUD, manifest validation
- `sensors/` — sensor CRUD
- `workflows/` — playbook CRUD
- `strategies/` — strategy selection + FSM spec CRUD
- `catalog/` — plain-language wrapper over Discovery
- `audit/` — audit reads/writes
- `observability/` — telemetry + signal log queries
- `persistence/` — snapshot records
- `secrets/` — Cloak-encrypted CRUD
- `integrations/` — provider configs
- `identities/`, `memory_spaces/`, `threads/` — auxiliary primitives
- `worker_pools/`, `schedules/`, `traces/` — auxiliary primitives

`jido_builder_runtime/lib/jido_builder_runtime/`:

- `jido.ex` — `use Jido, otp_app: :jido_builder`
- `application.ex` — supervision tree root
- `agents/dynamic_agent.ex`
- `agents/dynamic_pod.ex`
- `actions/dispatch.ex`
- `actions/directive_emitter.ex`
- `actions/state_op_action.ex`
- `actions/signal_builder.ex` (helper)
- `plugins/dynamic_plugin.ex`
- `sensors/dynamic_sensor.ex`
- `strategies/data_driven_fsm.ex`
- `telemetry/handler.ex`
- `telemetry/debug_tap.ex`
- `hiring.ex` — wraps `start_agent`, applies template config
- `persistence.ex` — wraps hibernate/thaw across adapters
- `sensor_host.ex` — starts/stops configured sensors
- `workflow_runner.ex` — executes playbook steps
- `pod_runtime.ex` — wraps `Jido.Pod.get/ensure_node/mutate`
- `cron_runtime.ex` — wires `Schedule` / `Cron` directives

`jido_builder_codegen/lib/jido_builder_codegen/`:

- `blocks/` — one module per block (Emit, Schedule, Branch, LoopWhile,
  CallLLM, HttpRequest, SetState, DeletePath, WaitFor, Forward, etc.)
- `templates/` — EEx files that render agents, actions, sensors,
  plugins, strategies
- `compiler.ex` — write file → `Code.compile_file/1` →
  `Jido.Discovery.refresh/0`
- `ejector.ex` — render "Export as Elixir" bundles
- `validator.ex` — validates block trees against manifest + schema

`jido_builder_generated/lib/jido_builder_generated/` — destination only:

- `actions/` — generated action modules
- `sensors/` — generated sensor modules
- `plugins/` — generated plugin modules
- `strategies/` — generated strategy modules
- `agents/` — generated fully custom agent modules (power-user mode)

`jido_builder_web/lib/jido_builder_web/` — LiveViews, components,
endpoints, router, telemetry subscriber.

---

## 3. Phase 3 — Product Design

### 3.1 Information architecture (global nav)

The nav exposes every Jido capability. Labels lead with plain language.

| Nav item | Screen group | Jido concepts covered |
|---|---|---|
| **Home** | Overview + live health | counts, telemetry roll-ups |
| **Workspaces** | Tenancy + partitions | `partition_key`, multi-tenancy |
| **Roster** | Team members (agents) | `start_agent`, `stop_agent`, lifecycle |
| **Templates** | Job templates (agent modules + config) | `use Jido.Agent`, schema, plugins, strategy, routes |
| **Skills** | Tools/actions catalog | `Jido.Discovery.list_actions`, built-in + generated |
| **Capability Packs** | Plugins | `Jido.Plugin`, routes, schedules, state slots |
| **Watchers** | Sensors | `Jido.Sensor`, Heartbeat, Bus, generated |
| **Work Styles** | Strategies | Direct, FSM, custom strategies |
| **Teams** | Pods | `Jido.Pod`, topology, mutation, nested |
| **Playbooks** | Workflows | signal chains, branching, parallelism |
| **Assignments** | Task console | `AgentServer.call/cast`, `Jido.Signal` |
| **Directives** | Effect builder | All 11 directive types |
| **State Ops** | State editor | All 5 state operations |
| **Threads** | Conversation/journal explorer | `Jido.Thread`, InMemory + JournalBacked |
| **Memory** | Memory spaces | `Jido.Memory.Space` |
| **Identities** | Profiles | `Jido.Identity.Profile` |
| **Activity** | Signals / directives / events | Telemetry + signals_log + directives_log |
| **Traces** | Distributed trace viewer | `Jido.Tracing.Context`, spans |
| **Audit** | Who changed what | audit_events |
| **Vault** | Snapshots + restore | `hibernate/thaw`, adapters |
| **Pools** | Worker pools | `Jido.Agent.WorkerPool` |
| **Schedules** | Cron + timers | declarative + dynamic cron, `Schedule` directive |
| **Hierarchy** | Parent/child/orphan view | `SpawnAgent`, `AdoptChild`, orphan lifecycle |
| **Integrations** | External providers | LLM, storage adapters, webhooks |
| **Settings** | Instance config + secrets | Jido opts, Cloak vault, debug level |
| **Ejector** | Export as Elixir | Codegen output bundles |
| **Glossary** | Plain-language translator | Term dictionary |

### 3.2 Plain-language translation layer (required, not optional)

Every screen shows the HR label first; the Jido label appears in a
tooltip, help drawer, and Advanced mode panel.

| Jido term | Builder label (plain) | Tooltip |
|---|---|---|
| Agent | Team member | A hired worker with a role and skills |
| Agent module | Job template | The role used when hiring |
| Action | Skill | Something a worker can do |
| Signal | Task / Message | A piece of work sent to a worker |
| Directive | Follow-up | A side effect the worker requested |
| State operation | Record change | An edit to the worker's running notes |
| Strategy | Work style | How the worker organizes multi-step work |
| Plugin | Capability pack | A bundle of related skills |
| Sensor | Watcher | A listener that triggers work automatically |
| Pod | Team | A group of workers that collaborate |
| Partition | Workspace | A separate area for a customer or project |
| Hibernate | Take leave | Save state and stop the worker |
| Thaw | Return from leave | Restore a saved worker |
| InstanceManager | HR records | Durable worker lifecycle registry |
| Thread | Conversation log | A journaled conversation the worker had |
| Memory space | Memory | Shared notes the worker can read/write |
| Identity profile | Profile | Who the worker is (name, role, traits) |
| Worker pool | Staffing pool | Pre-hired workers ready for a rush |
| Schedule | Reminder / Cron | A recurring task |
| Debug level | Verbosity | How much the worker's activity is logged |
| Discovery | Skills catalog | The library of available skills |
| `cmd/2` | (never shown) | — |

Advanced mode toggles expose the raw terms in panels.

### 3.3 Screen inventory (MVP tiers)

**Tier A — Vertical slice must ship first:**

1. App shell, nav, empty/loading/error states, command palette (Cmd+K)
2. Home / Overview (live counters, telemetry feed)
3. Templates Library + Template Editor (fields, routes, strategy,
   plugins, schedules, storage, debug)
4. Hire Agent Wizard (5 steps: workspace → template → persona →
   skills/plugins → review)
5. Agent Roster + Agent Detail (profile, live state, directives/events,
   controls)
6. Assignments Console (compose + send + live observe)
7. Activity / Signal Explorer (real telemetry)
8. Skills catalog (read from Discovery)
9. Work Styles (pick Direct / FSM with guided explanation)
10. Directives Builder (fire any of 11 directive types safely)

**Tier B — Team orchestration:**

11. Capability Packs (plugin browser + configurator)
12. Watchers (sensor browser + configurator)
13. Teams (pods with topology editor)
14. Hierarchy view (parent/child/orphan tree)
15. Playbooks (workflow builder)
16. State Ops editor (apply any of 5 state ops)
17. Schedules (cron + timers)

**Tier C — Operations and trust:**

18. Audit History
19. Vault (hibernate/thaw/snapshot + adapter picker)
20. Traces (span viewer)
21. Pools (worker pool config)
22. Settings / Integrations / Secrets
23. Workspaces (partitions for multi-tenancy)

**Tier D — Advanced authoring via codegen:**

24. Block Editor for custom Actions
25. Block Editor for custom Sensors
26. Block Editor for custom Plugins
27. Block Editor for custom Strategies
28. FSM Designer (states, events, guards, effects)
29. Ejector (export-as-Elixir)

**Tier E — Awareness and polish:**

30. Threads explorer
31. Memory spaces
32. Identity profiles
33. Glossary
34. Onboarding walkthrough
35. Debug panel (live ring buffer from `AgentServer.recent_events/2`)
36. Error policy editor (maps to `Jido.AgentServer.ErrorPolicy`)
37. Orphans & Adoption view (handles `jido.agent.orphaned` signal)

Every nav item in Section 3.1 must have at least one screen in Tiers
A–E. Do not mark a tier done until its acceptance tests pass.

### 3.4 UX must-haves (non-negotiable)

- Every destructive action behind a confirmation modal naming specific
  consequences (e.g., "This will stop worker X and discard 3 in-flight
  tasks").
- Empty states explain what the screen is for and offer a first action.
- Error states show the error, probable cause, and next step — never a
  raw stacktrace.
- Loading states use skeleton rows, not spinners.
- Accessibility: labelled controls, focus rings, keyboard nav in
  wizards, `aria-live` on activity streams, high-contrast by default.
- Command palette (Cmd+K): jump to agent, run assignment, switch screen.
- Dark mode respecting system preference.
- Every LiveView that shows live data subscribes to PubSub, never polls.
- No lorem ipsum, no fake charts, no decorative unwired controls.
- Every context-module write emits an `audit_events` row.

### 3.5 Honest UI rules

If a surface is not wired, it must either:
(a) not ship, or
(b) render an "Unavailable in MVP — tracked as `<gap-id>`" card that
    names the exact Jido primitive it needs.

Never paint a control that does nothing when clicked.

---

## 4. Phase 4 — Build

### 4.1 Bootstrap (Codex: start here)

```bash
# from JidoBuilder/ repo root
cd .                                # stay at repo root
mix archive.install hex phx_new --force

# Create umbrella
mix phx.new builder \
  --umbrella \
  --live \
  --database sqlite3 \
  --no-mailer \
  --no-gettext \
  --module JidoBuilder \
  --app jido_builder

cd builder
```

`mix phx.new --umbrella` produces `apps/jido_builder` and
`apps/jido_builder_web`. **Rename and split** to match Section 0.2:

```bash
# Inside builder/apps/
mv jido_builder jido_builder_core
# Generate the additional apps:
cd apps
mix new jido_builder_runtime --sup
mix new jido_builder_codegen --sup
mix new jido_builder_generated --sup
```

Update each new app's `mix.exs` to:

- Declare `in_umbrella: true` and `deps_path: "../../deps"`,
  `lockfile: "../../mix.lock"`, `build_path: "../../_build"`,
  `config_path: "../../config/config.exs"`
- Add dependencies per the graph in Section 2.4
- `jido_builder_runtime`, `jido_builder_codegen`, and
  `jido_builder_generated` must declare `{:jido, path: "../../..",
  override: true}` to pick up the upstream library from the repo root
- `jido_builder_web` depends on `jido_builder_core`,
  `jido_builder_runtime`, and `jido_builder_codegen` as
  `{:jido_builder_core, in_umbrella: true}` etc.

Rename and move the generated scaffolding so that:

- Ecto repo lives in `jido_builder_core`
- LiveView endpoint lives in `jido_builder_web`
- The `JidoBuilder.Jido` instance module lives in `jido_builder_runtime`

Commit the scaffold before writing feature code.

### 4.2 Wire Jido into supervision (in `jido_builder_runtime`)

```elixir
# apps/jido_builder_runtime/lib/jido_builder_runtime/jido.ex
defmodule JidoBuilder.Jido do
  use Jido, otp_app: :jido_builder
end
```

```elixir
# apps/jido_builder_runtime/lib/jido_builder_runtime/application.ex
defmodule JidoBuilderRuntime.Application do
  use Application

  def start(_type, _args) do
    Jido.Discovery.init_async()

    children = [
      JidoBuilder.Jido,
      JidoBuilderRuntime.TelemetryHandler,
      JidoBuilderRuntime.SensorHost,
      JidoBuilderRuntime.WorkflowRunner,
      JidoBuilderRuntime.DebugEventTap,
      JidoBuilderCodegen.CompileQueue
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: JidoBuilderRuntime.Supervisor)
  end
end
```

Configuration in `config/config.exs`:

```elixir
config :jido_builder, JidoBuilder.Jido,
  max_tasks: 1000,
  agent_pools: [],
  storage: {Jido.Storage.ETS, [table: :jido_builder_storage]}
```

### 4.3 Data-driven runtime (Path A)

Implement every module listed in Section 2.5 under
`jido_builder_runtime`. The core pieces:

```elixir
# apps/jido_builder_runtime/lib/jido_builder_runtime/agents/dynamic_agent.ex
defmodule JidoBuilder.Runtime.DynamicAgent do
  use Jido.Agent,
    name: "builder_dynamic_agent",
    description: "Template-driven agent",
    schema: [
      template_id: [type: :string, required: true],
      persona: [type: :string, default: ""],
      enabled_action_slugs: [type: {:list, :string}, default: []],
      allowed_plugins: [type: {:list, :string}, default: []],
      runtime_state: [type: :map, default: %{}]
    ]

  def on_before_cmd(agent, action) do
    # Audit log every incoming action with correlation id
    {:ok, agent, action}
  end

  def on_after_cmd(agent, _action, directives) do
    # Validate + emit to PubSub for LiveView subscribers
    {:ok, agent, directives}
  end
end
```

```elixir
# apps/jido_builder_runtime/lib/jido_builder_runtime/actions/dispatch.ex
defmodule JidoBuilder.Runtime.Actions.Dispatch do
  use Jido.Action,
    name: "dispatch",
    description: "Allow-listed dispatch to a discovered action",
    schema: [
      action_slug: [type: :string, required: true],
      params: [type: :map, default: %{}]
    ]

  def run(%{action_slug: slug, params: params}, context) do
    with %{module: mod} <- Jido.Discovery.get_action_by_slug(slug),
         true <- slug in context.state.enabled_action_slugs,
         {:ok, result} <- Jido.Exec.run(mod, params, context) do
      merged = Map.merge(context.state.runtime_state || %{}, result || %{})
      {:ok, %{runtime_state: merged}, []}
    else
      false ->
        {:error, Jido.Error.validation_error("action not allowed for this template")}

      _ ->
        {:error, Jido.Error.validation_error("unknown action slug")}
    end
  end
end
```

Implement one generic action per directive kind and per state op so the
Directives/State Ops builder screens can emit real effects from stored
config. These actions accept a payload and return the appropriate
directive or state op from the return tuple.

### 4.4 Telemetry → PubSub + DB bridge

```elixir
# apps/jido_builder_runtime/lib/jido_builder_runtime/telemetry/handler.ex
defmodule JidoBuilderRuntime.TelemetryHandler do
  use GenServer

  @events [
    [:jido, :agent, :cmd, :start],
    [:jido, :agent, :cmd, :stop],
    [:jido, :agent, :cmd, :exception],
    [:jido, :agent_server, :signal, :start],
    [:jido, :agent_server, :signal, :stop],
    [:jido, :agent_server, :signal, :exception]
  ]

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def init(_) do
    :telemetry.attach_many(
      "jido-builder-handler",
      @events,
      &__MODULE__.handle_event/4,
      nil
    )
    {:ok, nil}
  end

  def handle_event(event, measurements, metadata, _config) do
    # 1. Persist to signals_log / directives_log / audit_events
    JidoBuilderCore.Observability.record(event, measurements, metadata)

    # 2. Broadcast to PubSub topics LiveViews subscribe to
    agent_id = metadata[:agent_id]
    Phoenix.PubSub.broadcast(JidoBuilder.PubSub, "overview", {:telemetry, event, metadata})
    if agent_id do
      Phoenix.PubSub.broadcast(JidoBuilder.PubSub, "agent:#{agent_id}", {:telemetry, event, metadata})
    end
    Phoenix.PubSub.broadcast(JidoBuilder.PubSub, "activity:global", {:telemetry, event, metadata})
  end
end
```

Topics the Web app subscribes to:

- `"overview"` — dashboard counters
- `"agent:<id>"` — per-agent detail
- `"activity:global"` — activity stream
- `"pod:<id>"` — pod detail
- `"trace:<id>"` — trace viewer
- `"workflow:<id>"` — playbook run
- `"sensor:<id>"` — sensor firings

### 4.5 Codegen (Path B)

```elixir
# apps/jido_builder_codegen/lib/jido_builder_codegen/compiler.ex
defmodule JidoBuilderCodegen.Compiler do
  @generated_root "apps/jido_builder_generated/lib/jido_builder_generated"

  def compile_action(generated_action) do
    source = render_action(generated_action)
    path = Path.join([@generated_root, "actions", "#{generated_action.file_name}.ex"])
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, source)

    # Compile into the running VM
    [{module, _}] = Code.compile_file(path)

    # Refresh Discovery so the new module is picked up
    :ok = Jido.Discovery.refresh()

    {:ok, module}
  end

  defp render_action(generated) do
    EEx.eval_file(
      "priv/templates/action.ex.eex",
      assigns: [
        module_name: generated.module_name,
        name: generated.name,
        description: generated.description,
        schema: generated.schema,
        blocks: generated.blocks
      ],
      trim: true
    )
  end
end
```

EEx templates live in `apps/jido_builder_codegen/priv/templates/`:

- `action.ex.eex` — generates a `use Jido.Action` module
- `sensor.ex.eex` — generates a `use Jido.Sensor` module
- `plugin.ex.eex` — generates a `use Jido.Plugin` module
- `strategy.ex.eex` — generates a strategy module that implements
  `Jido.Agent.Strategy` callbacks by composing blocks
- `agent.ex.eex` — generates a fully-custom `use Jido.Agent` module

**Blocks** are the only user-composable units. Each block is a struct
plus an EEx snippet that produces Elixir. Examples:

- `%Block.Emit{signal_type: ..., data: ...}` → renders a
  `Jido.Agent.Directive.emit(...)` call
- `%Block.Schedule{delay_ms: ..., message: ...}` → renders
  `Jido.Agent.Directive.schedule(...)`
- `%Block.SetState{assigns: %{...}}` → renders a `StateOp.SetState`
- `%Block.CallLLM{provider: ..., prompt_ref: ...}` → renders a
  `jido_ai` call (only if integration configured)
- `%Block.Branch{condition_ref: ..., then_blocks: ..., else_blocks: ...}`
- `%Block.LoopWhile{condition_ref: ..., body_blocks: ...}`

The Web app exposes each block as a draggable card in the Block Editor.
Block trees are persisted in `generated_actions.blocks` (JSON) so they
can be edited after creation without re-parsing source.

**Hot compile safety:** all writes go through
`JidoBuilderCodegen.CompileQueue`, a GenServer that serializes compile
requests, runs them in a `Task.Supervisor`-supervised task, captures
compiler output, surfaces errors back to the UI, and triggers a
`Jido.Discovery.refresh/0` on success. Failed compiles roll back the
file to its prior content.

### 4.6 LiveView modules (all 37 screens)

```
apps/jido_builder_web/lib/jido_builder_web/live/
├── home_live.ex
├── workspaces/index_live.ex
├── workspaces/show_live.ex
├── roster/
│   ├── index_live.ex
│   ├── show_live.ex
│   └── hire_wizard_live.ex
├── templates/index_live.ex
├── templates/edit_live.ex
├── templates/fsm_designer_live.ex
├── skills/index_live.ex
├── skills/detail_live.ex
├── capability_packs/
│   ├── index_live.ex
│   └── edit_live.ex
├── watchers/
│   ├── index_live.ex
│   └── edit_live.ex
├── work_styles/index_live.ex
├── work_styles/custom_edit_live.ex
├── teams/
│   ├── index_live.ex
│   ├── show_live.ex
│   └── topology_edit_live.ex
├── hierarchy/show_live.ex
├── playbooks/
│   ├── index_live.ex
│   └── edit_live.ex
├── assignments/
│   ├── new_live.ex
│   └── show_live.ex
├── directives/builder_live.ex
├── state_ops/editor_live.ex
├── threads/
│   ├── index_live.ex
│   └── show_live.ex
├── memory/
│   ├── index_live.ex
│   └── show_live.ex
├── identities/
│   ├── index_live.ex
│   └── show_live.ex
├── activity/index_live.ex
├── traces/
│   ├── index_live.ex
│   └── show_live.ex
├── audit/index_live.ex
├── vault/
│   ├── index_live.ex
│   └── restore_live.ex
├── pools/index_live.ex
├── schedules/index_live.ex
├── integrations/index_live.ex
├── settings/index_live.ex
├── ejector/index_live.ex
├── glossary/index_live.ex
├── debug/live_ring_live.ex
├── error_policy/edit_live.ex
└── block_editor/
    ├── action_live.ex
    ├── sensor_live.ex
    ├── plugin_live.ex
    └── strategy_live.ex
```

---

## 5. Phase 5 — Test

### 5.1 Unit tests (per app)

- **Core:** context modules CRUD, schema validations, Cloak encryption
- **Runtime:** DynamicAgent route resolution, Dispatch allowlist,
  directive emitter coverage for all 11 directive types, state op
  coverage for all 5 ops, telemetry handler fan-out
- **Codegen:** block tree → Elixir source determinism, compile queue
  serialization, Discovery refresh on success, rollback on failure
- **Web:** component rendering, form validation, plain-language labels

### 5.2 Integration tests

- Hire → signal → call → state updated → recorded in signals_log
- Hibernate → restart app → thaw → state preserved (per storage
  adapter: ETS, File, Redis-optional)
- Pod creation with mixed eager/lazy members → `Jido.Pod.get/2` returns
  running pod → `ensure_node/3` activates lazy member
- Workflow with 5 steps including a branch and a schedule directive
  runs to completion
- Generated action compiled from block tree executes via Dispatch
- Custom generated sensor fires heartbeat → signal reaches agent
- FSM strategy transitions match the spec defined in the designer
- Orphan lifecycle: spawn child → kill parent → orphan signal appears
  → adopt via `AdoptChild` directive

### 5.3 End-to-end tests (Playwright)

Implement all four scenarios from the brief, plus:

5. Create a custom action in the Block Editor → save → verify it
   appears in Skills and is selectable in a template.
6. Wire an LLM integration (fake provider) → make an agent call it →
   see the response in the activity stream and thread log.
7. Stop an agent cleanly → hibernate → thaw into a new partition →
   confirm state preserved and audit trail unbroken.
8. Trigger an error in an action → confirm error policy UI shows it
   and offers restart/stop/continue options.
9. Schedule a cron → fast-forward time in test → confirm the scheduled
   signal reached the agent.
10. Create a pod with 3 members → send a broadcast signal → confirm
    every member received and processed it.

### 5.4 Accessibility and performance

- All primary screens pass axe-core checks via Playwright
- First meaningful paint < 1s on Home with 10 running agents
- Activity stream sustains 50 events/sec without UI lag
- Hire wizard completes in ≤ 2 seconds end-to-end with a warm BEAM

---

## 6. Phase 6 — Verify (pass 3 validation)

Produce `builder/docs/verification.md` with one row per Jido
capability from Section 0.3 and Section 3.1. Columns:

| Capability | UI screen(s) | Path | Jido primitive | Status | Confidence | Notes |
|---|---|---|---|---|---|---|

Every primitive must be present and explicitly marked. No hand-waving.

Also produce:

- `builder/docs/capability_map.md` (Phase 1 output, updated)
- `builder/docs/next_steps.md` — deferred backlog with gap IDs
- `builder/docs/run.md` — local-run instructions in ≤ 5 minutes
- `builder/docs/architecture.md` — diagrams, context modules, flow charts
- `builder/docs/security.md` — codegen sandbox, secrets handling,
  destructive-action guardrails

---

## 7. Exhaustive Feature Mapping Matrix

Every Jido capability, mapped to its Builder surface and implementation path.

### 7.1 Agents & lifecycle

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Start agent | Roster → Hire wizard | A | `Jido.start_agent/3` |
| Stop agent | Roster → Fire | A | `Jido.stop_agent/2` |
| List running agents | Roster index | A | `Jido.list_agents/2` |
| Count agents | Home dashboard | A | `Jido.agent_count/2` |
| Whereis by ID | Detail screens (internal) | A | `Jido.whereis/3` |
| Define agent schema | Template editor → Fields | A | DynamicAgent config |
| `on_before_cmd` hook | Template editor → Hooks (advanced) | B | Generated agent module |
| `on_after_cmd` hook | Template editor → Hooks (advanced) | B | Generated agent module |
| Define fully custom agent | Block Editor → Agent | B | Generated agent module |

### 7.2 Actions

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Browse catalog | Skills index | A | `Jido.Discovery.list_actions/1` |
| Lookup by slug | Skill detail | A | `Jido.Discovery.get_action_by_slug/1` |
| Execute action | Assignments console | A | `Jido.Exec.run/3` via Dispatch |
| Define custom action | Block Editor → Action | B | Generated action module |
| Filter by category/tag | Skills index filters | A | Discovery filter options |
| Execute with timeout/retries | Assignments advanced | A | `cmd/3` options |
| Register with Discovery | Automatic on compile | B | `Discovery.refresh/0` |

### 7.3 Signals & routing

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Create signal | Assignments composer | A | `Jido.Signal.new!/3` |
| Send synchronous | Assignments composer | A | `AgentServer.call/3` |
| Send async | Assignments composer | A | `AgentServer.cast/2` |
| Define agent routes | Template editor → Routes | A | Signal routes field |
| Define plugin routes | Capability Pack edit | A | Plugin routes rows |
| Define strategy routes | Work Styles edit (advanced) | B | Generated strategy |
| Wildcard patterns | Route editor | A | Plugin `signal_patterns` |
| CloudEvents fields | Composer (advanced) | A | `Jido.Signal` struct |

### 7.4 Directives (all 11 types)

| Directive | Builder surface | Path | Jido primitive |
|---|---|---|---|
| `Emit` | Directive Builder → Emit | A | `Directive.emit/1,2` |
| `Error` | Directive Builder → Fail | A | `Directive.error/1` |
| `Spawn` | Directive Builder → Run Task | A | `Directive.spawn/1` |
| `SpawnAgent` | Directive Builder → Hire Child | A | `Directive.spawn_agent/2,3` |
| `AdoptChild` | Hierarchy view → Adopt | A | `Directive.adopt_child/2,3` |
| `StopChild` | Hierarchy view → Fire Child | A | `Directive.stop_child/1,2` |
| `Schedule` | Schedules screen | A | `Directive.schedule/2` |
| `RunInstruction` | Directive Builder → Run Block | A | `Directive.run_instruction/2` |
| `Stop` | Roster → Stop | A | `Directive.stop/0,1` |
| `Cron` | Schedules → New cron | A | `Directive.cron/2,3` |
| `CronCancel` | Schedules → Cancel | A | `Directive.cron_cancel/1` |

### 7.5 State operations (all 5)

| Op | Builder surface | Path | Jido primitive |
|---|---|---|---|
| `SetState` | State Ops editor | A | `StateOp.SetState` |
| `ReplaceState` | State Ops editor | A | `StateOp.ReplaceState` |
| `DeleteKeys` | State Ops editor | A | `StateOp.DeleteKeys` |
| `SetPath` | State Ops editor | A | `StateOp.SetPath` |
| `DeletePath` | State Ops editor | A | `StateOp.DeletePath` |

### 7.6 Strategies

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Direct | Work Styles → pick | A | `Strategy.Direct` |
| FSM | Work Styles → pick + Designer | A+B | `Strategy.FSM` |
| Custom strategy | Block Editor → Strategy | B | Generated strategy module |
| Strategy signal routes | Strategy edit | B | `signal_routes/1` |

### 7.7 Plugins

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Browse plugins | Capability Packs index | A | `Jido.Discovery.list_plugins/1` |
| Define plugin | Capability Pack edit | B | Generated plugin |
| Plugin state slot | Plugin edit → State | B | Generated plugin module |
| Plugin routes | Plugin edit → Routes | A | Plugin routes rows |
| Plugin schedules | Plugin edit → Schedules | A | Plugin schedules rows |
| Plugin lifecycle hooks | Plugin edit → Hooks (advanced) | B | Generated plugin |
| Default plugins | Settings → Defaults | A | Config flag |

### 7.8 Sensors

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Browse sensors | Watchers index | A | `Jido.Discovery.list_sensors/1` |
| Heartbeat sensor | Watcher edit → Heartbeat | A | `Jido.Sensors.Heartbeat` |
| Bus sensor | Watcher edit → Bus | A | `Jido.Sensors.Bus` |
| Define custom sensor | Block Editor → Sensor | B | Generated sensor |
| Enable/disable sensor | Watchers index | A | SensorHost |
| Sensor parameters | Watcher edit | A | Sensor spec |

### 7.9 Pods

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Define pod | Teams → New | A | DynamicPod topology |
| Eager members | Topology editor | A | `:eager` activation |
| Lazy members | Topology editor | A | `:lazy` activation |
| Nested pods | Topology editor | A | Nested topology node |
| Mutate topology | Teams → Edit | A | `Jido.Pod.mutate/3` |
| Pod actions (Mutate/Evolve) | Teams detail | A | `Pod.Actions.Mutate`, `Evolve` |
| Ensure node | Teams detail → Activate | A | `Jido.Pod.ensure_node/3` |

### 7.10 Persistence and storage

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Hibernate | Vault → Take leave | A | `Jido.hibernate/2` |
| Thaw | Vault → Restore | A | `Jido.thaw/3` |
| ETS adapter | Settings → Storage | A | `Jido.Storage.ETS` |
| File adapter | Settings → Storage | A | `Jido.Storage.File` |
| Redis adapter | Settings → Storage (optional) | A | `Jido.Storage.Redis` |
| InstanceManager | Runtime setup per template | A | `Jido.Agent.InstanceManager` |
| Snapshot metadata | Vault → Snapshots | A | snapshots table |

### 7.11 Multi-tenancy

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Workspace (partition) | Workspaces → New | A | `Jido.partition_key/2` |
| Partition-scoped list | Workspaces → show | A | `list_agents(partition: ...)` |
| Partition-safe hibernate | Vault → partition filter | A | `hibernate(partition: ...)` |

### 7.12 Worker pools

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Define pool | Pools → New | A | `agent_pools` config |
| Set size | Pools → edit | A | `size`, `max_overflow` |
| Check pool out | Automatic on hire when pool_key set | A | `Jido.Agent.WorkerPool` |

### 7.13 Scheduling

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Declarative schedules | Template edit → Schedules | A | `schedules:` option |
| Dynamic cron | Schedules → New | A | `Directive.Cron` |
| Cancel cron | Schedules → Cancel | A | `Directive.CronCancel` |
| Schedule delayed message | Directives → Schedule | A | `Directive.Schedule` |
| Schedule signal | Schedules → New signal | A | `ScheduleSignal` action |
| Schedule timeout | Template edit → Timeout | A | `ScheduleTimeout` action |

### 7.14 Observability

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Live telemetry | Activity screen | A | Telemetry events |
| Per-agent events | Agent detail | A | `recent_events/2` |
| Debug level | Settings + Debug panel | A | `Jido.Debug` |
| Debug ring buffer | Debug panel | A | `recent_events/2` |
| Traces | Traces screen | A | `Jido.Tracing.Context` |
| Signal log | Activity + filters | A | signals_log table |
| Directive log | Directives view | A | directives_log table |
| Metrics | Home dashboard | A | telemetry_metrics rollups |

### 7.15 Error handling

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Error policy | Error Policy editor | A | `Jido.AgentServer.ErrorPolicy` |
| Restart strategy | Template → Restart | A | `restart:` option |
| Stop on error | Template → Error policy | A | Policy config |

### 7.16 Coordination

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Wait for completion | Assignments detail | A | `Jido.Await.completion/2,3` |
| Wait for child | Hierarchy detail | A | `Await.child/3,4` |
| Wait all | Playbook runner | A | `Await.all/2,3` |
| Wait any | Playbook runner | A | `Await.any/2,3` |
| Alive check | Roster status badge | A | `Await.alive?/1` |
| Cancel | Roster → Cancel | A | `Await.cancel/1,2` |
| Get children | Hierarchy view | A | `Await.get_children/1` |
| Get child by tag | Hierarchy view | A | `Await.get_child/2` |
| Parent binding lookup | Hierarchy view | A | `Jido.parent_binding/2,3` |

### 7.17 Threads, memory, identity

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Thread history | Threads index | A | `Jido.Thread.Store` |
| InMemory thread store | Threads index filter | A | `InMemory` adapter |
| Journaled thread store | Threads index filter | A | `JournalBacked` adapter |
| Thread plugin | Template → plugins | A | `Jido.Thread.Plugin` |
| Memory space | Memory index | A | `Jido.Memory.Space` |
| Memory plugin | Template → plugins | A | `Jido.Memory.Plugin` |
| Identity profile | Identities index | A | `Jido.Identity.Profile` |
| Identity plugin | Template → plugins | A | `Jido.Identity.Plugin` |

### 7.18 Built-in actions (full coverage)

| Built-in action | Builder exposure |
|---|---|
| `Jido.Actions.Control.Broadcast` | Assignments → Broadcast mode |
| `Jido.Actions.Control.Cancel` | Roster → Cancel |
| `Jido.Actions.Control.Forward` | Playbook step → Forward |
| `Jido.Actions.Control.Noop` | Block Editor utility |
| `Jido.Actions.Control.Reply` | Assignments → Reply option |
| `Jido.Actions.Lifecycle.NotifyParent` | Hierarchy → Notify parent |
| `Jido.Actions.Lifecycle.NotifyPid` | Advanced only |
| `Jido.Actions.Lifecycle.SpawnChild` | Hierarchy → Add child |
| `Jido.Actions.Lifecycle.StopChild` | Hierarchy → Stop child |
| `Jido.Actions.Lifecycle.StopSelf` | Roster → Self-stop |
| `Jido.Actions.Scheduling.ScheduleCron` | Schedules → New |
| `Jido.Actions.Scheduling.CancelCron` | Schedules → Cancel |
| `Jido.Actions.Scheduling.ScheduleSignal` | Schedules → Schedule signal |
| `Jido.Actions.Scheduling.ScheduleTimeout` | Template → timeout |
| `Jido.Actions.Status.MarkCompleted` | Auto on happy path |
| `Jido.Actions.Status.MarkFailed` | Auto on errors |
| `Jido.Actions.Status.MarkIdle` | Auto |
| `Jido.Actions.Status.MarkWorking` | Auto |
| `Jido.Actions.Status.SetStatus` | Advanced UI |

### 7.19 Testing (creator-level)

| Capability | Builder surface | Path |
|---|---|---|
| Pure-function test of template | Template → "Test this" | A runs `cmd/2` against a sample signal |
| Fixture signal playback | Activity → Replay | A |

### 7.20 Configuration

| Capability | Builder surface | Path | Jido primitive |
|---|---|---|---|
| Instance config | Settings | A | `config :jido_builder, JidoBuilder.Jido` |
| Debug config | Settings → Debug | A | `Jido.Debug` |
| Observability config | Settings → Observability | A | `config :jido, :observability` |
| Redaction | Settings → Privacy | A | `redact_sensitive` |

### 7.21 Export (Ejector)

| Capability | Builder surface | Path |
|---|---|---|
| Export template as Elixir | Ejector → Export template | B |
| Export generated action | Ejector → Export action | B |
| Export pod as Elixir | Ejector → Export pod | B |

Every row above must appear in `builder/docs/verification.md` with a
confidence rating by the end of Phase 6.

---

## 8. Hard Rules for Codex

1. **No fiction.** If a feature cannot be wired to a real Jido primitive,
   document it as a Builder abstraction or defer it. Do not paint fake UI.
2. **No upstream edits.** Treat `lib/jido/`, top-level `mix.exs`, and
   upstream `guides/` as read-only. All your code goes in `builder/`.
3. **No `Code.eval_string` on user input.** Codegen composes EEx
   templates from curated blocks only. The user never types Elixir.
4. **Generated files go only into `jido_builder_generated`.** No writes
   into other app directories.
5. **Plain language by default.** Advanced terminology lives behind a
   toggle. Jargon-free copy in empty, error, and confirmation states.
6. **Every destructive action requires confirmation** with specific
   consequences stated.
7. **Every screen must have loading, empty, and error states.**
8. **Every LiveView that shows live data must subscribe to PubSub, not
   poll.**
9. **Every context-module write must emit an audit event.**
10. **Tests must run via `mix test` at the umbrella root with zero
    external dependencies.**
11. **The Builder must work fully offline.** No outbound HTTP unless the
    user configures an integration.
12. **No secret leakage.** Cloak encryption for all integration secrets,
    redacted displays by default, and no secrets ever copied into
    generated Elixir files.
13. **Compile failures must roll back.** The CompileQueue restores the
    prior file and surfaces the error without killing the app.
14. **Every capability in Section 7 must have an entry in
    `verification.md` with an explicit status.** No omissions.

---

## 9. Execution Order (Codex: follow this order)

1. Read Section 0 and the guides listed in Section 1.
2. Bootstrap umbrella (Section 4.1). Commit scaffold.
3. Create the five apps and wire dependency graph (Section 2.4).
4. Wire Jido supervision (Section 4.2). Commit.
5. Implement `jido_builder_core` schemas and contexts for all tables
   in Section 2.3.
6. Implement `jido_builder_runtime` (Section 4.3) including DynamicAgent,
   Dispatch, DirectiveEmitter, StateOpAction, DynamicPod, DynamicPlugin,
   DynamicSensor, TelemetryHandler, SensorHost, PodRuntime, Hiring,
   Persistence, WorkflowRunner.
7. Implement `jido_builder_codegen` CompileQueue, Compiler, blocks,
   EEx templates.
8. Ship Tier A screens end-to-end with tests. Run Scenario A until green.
9. Ship Tier B. Run Scenario B until green.
10. Ship Tier C. Run Scenario C until green.
11. Ship Tier D (codegen/block editors). Run generated-capability tests
    until green.
12. Ship Tier E polish + glossary + onboarding.
13. Produce verification artifacts (Section 6) with all rows filled.
14. Write `builder/docs/run.md` with exact local-run commands.

At each tier, run the full umbrella test suite. Do not proceed if any
test is red.

---

## 10. Open Questions (flag to the user, do not guess)

- **LLM provider.** The Builder ships with no LLM dependency by default.
  If the user wants `jido_ai` integration with a local model (Ollama,
  LM Studio), wire it as an optional capability behind Settings →
  Integrations. Ask before selecting a provider.
- **Default storage adapter.** Default to ETS for MVP. File and Redis
  adapters are selectable per template. Ask before making either the
  default.
- **Multi-user authentication.** MVP is single-user localhost. Ask
  before adding auth/SSO.
- **Workflow engine depth.** MVP supports linear chains, branches, and
  parallel fan-out. Guards/loops beyond Block Editor primitives are
  deferred unless user prioritizes them.
- **Codegen deployment mode.** In dev, `Code.compile_file/1` hot-loads
  new modules. In `MIX_ENV=prod`, Codex must confirm whether the user
  wants hot compile (same pattern) or a restart-required mode (files
  written to disk, picked up on next boot). Ask.

---

## 11. Definition of Done

The Builder is done when:

- `cd builder && mix deps.get && mix ecto.setup && mix phx.server`
  launches the app at `http://localhost:4000`.
- Every row in Section 7 has a status + confidence rating in
  `builder/docs/verification.md`.
- A non-technical user, given only the onboarding walkthrough, can
  complete all four scenarios from the brief plus the six additional
  Tier D/E scenarios in Section 5.3 without editing any Elixir file.
- `mix test` at the umbrella root is green across all five apps.
- Every destructive action has a confirmation with specific
  consequences.
- No screen renders fake data or unwired controls.
- `builder/docs/run.md` lets another engineer run the app in under
  five minutes from a clean clone.
- Every Jido primitive from Section 0.3 is either (a) exposed in the UI
  with working wires, (b) explicitly documented as a Builder abstraction
  with transparent mapping, or (c) listed in `next_steps.md` with an
  explicit gap ID and the runtime dependency it needs.

**Begin by reading Section 0, then Section 1's guides, then bootstrap.**
