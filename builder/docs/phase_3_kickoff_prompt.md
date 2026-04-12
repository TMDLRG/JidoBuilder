# Phase 3 Kickoff Prompt

Paste the content below into a new Claude Code chat to continue the JidoBuilder phased implementation.

---

## Context

You are continuing the phased DDTDD implementation of **JidoBuilder**, a no-code Phoenix LiveView UI for the Jido Elixir agent framework. The canonical plan lives at `builder/docs/phase_1_to_8_plan.md`.

### What's already done

| Phase | Items | Status |
|---|---|---|
| Phase 0 | Umbrella scaffold, schemas, runtime wiring | closed (commit c094e87) |
| 7.3 | Cloak key rotation (SQLite-safe, custom Mix task) | done |
| 7.5 | Path-allowlist fuzz (1000-run StreamData) | done |
| 7.6 | EEx template fuzz (module-name validation + `inspect(description)`) | done |
| 7.13 | Local PBKDF2 single-user auth (5 required assertions) | done |
| Phase 1 | 1.1 Roster hire, 1.2 Assignments console, 1.3 Activity translation, 1.4 Stop with confirm, 1.5 Playwright skeleton | done |
| 7.14 | Hammer rate limit on /assignments (10 req/min/user) | done |
| Phase 2 | 2.1 App shell nav, 2.2 Home KPIs, 2.3 Templates index, 2.4 Template editor, 2.5 Agent detail, 2.6 Skills catalog, 2.7 Work Styles, 2.8 Directives builder | done |
| 7.11 | Structured JSON logger (prod config) | done |
| 7.12 | Prometheus `/metrics` endpoint | done |

**Baseline**: 67 tests + 4 properties + 2 doctests, 0 failures. All changes are uncommitted on `main`.

### Key architecture facts

- **Umbrella apps**: `jido_builder_core` (Ecto/SQLite3), `jido_builder_runtime` (Jido lifecycle), `jido_builder_codegen` (template rendering), `jido_builder_generated` (output), `jido_builder_web` (Phoenix LV)
- **Auth**: `JidoBuilderWeb.UserAuth` plug + `on_mount :ensure_authenticated` hook; `/healthz`, `/readyz`, `/metrics` bypass auth (API scope)
- **Roster**: `JidoBuilderRuntime.Roster.hire/3` → `Hiring.start/3` → `Jido.start_agent/3`; persists `agent_instances` row + `roster.hire` audit event; broadcasts `{:roster_hire, instance}` on workspace activity PubSub topic
- **Agents**: `JidoBuilderRuntime.BareAgent` is the Phase 1 no-op agent; `DynamicAgent.from_template/2` is the template-backed one for Phase 2+
- **Observability**: `Observability.translate_event/1` turns raw telemetry maps into `%{label, status, agent_link, ts, next_hint}` for human-readable display
- **PubSub topics**: `EventBus.workspace_activity_topic/1`, `agent_topic/2`, `workflow_topic/2`, `workflow_activity_topic/1`
- **DB**: SQLite3 via `ecto_sqlite3`; no `FOR UPDATE` locks; no `Task.async_stream` in sandbox tests
- **Deps added so far**: `pbkdf2_elixir`, `stream_data` (test), `hammer`, `telemetry_metrics_prometheus_core`
- **ConnCase helper**: `log_in_user/1,2` stores a session token; `@moduletag :authenticated` auto-logs-in via setup
- **Existing runtime wrappers** (already implemented, just need LV wiring): `Discovery.list_actions/1`, `Hiring.{start,stop,list,count,whereis}`, `Signals.{new,call,cast}`, `DirectiveEmitter.from_config/1`, `PodRuntime.boot/2`, `SensorHost.start_link/1`

### Existing stubs that Phase 3 extends

- `workflow_builder_live.ex` — has PubSub subscription + event stream; needs D3 DAG hook integration
- `schedules_live.ex` — 6-line stub, needs cron CRUD via `Jido.Scheduler`
- `teams_live.ex` — 6-line stub, needs pod CRUD via `PodRuntime`

## Your task: Execute Phase 3

Read `builder/docs/phase_1_to_8_plan.md` lines 345–378 for the full Phase 3 spec.

**Phase 3 — Tier B (team orchestration) — 7 surfaces + 7.10 interleave:**

| # | Surface | Closes | Key Runtime Call |
|---|---|---|---|
| 3.1 | Capability Packs (plugin browser + edit) | GAP-MVP-008 | `Discovery.list_plugins/1` + template plugin rows |
| 3.2 | Watchers (sensor browser + configurator) | GAP-MVP-008 | `Discovery.list_sensors/1` + `SensorHost` |
| 3.3 | Teams / Pods MVP | GAP-MVP-012 | `PodRuntime.boot/2` + pod topology DB rows |
| 3.4 | Hierarchy view | GAP-MVP-009 | Parent/child agent relationships |
| 3.5 | Playbooks / Workflow Builder (D3 DAG) | GAP-MVP-002 | `workflow_steps` DB + JS hook `pushEvent("init_graph")` |
| 3.6 | State Ops editor (all 5 ops) | GAP-MVP-005 | `SetState`, `ReplaceState`, `DeleteKeys`, `SetPath`, `DeletePath` |
| 3.7 | Schedules (cron create/cancel) | GAP-MVP-006 | `Jido.Scheduler` + `Directive.cron/2` + `Directive.cron_cancel/1` |
| 7.10 | SQLite WAL-aware backup script | — | `infra/backup.sh` with `sqlite3 <db> ".backup <dest>"` |

### Rules (same as all prior phases)

1. **DDTDD per item**: Discovery → RED test → verify RED → GREEN → REFACTOR → VALIDATE → DONE
2. **One PR per work item** — no bundling, no sweeping refactors
3. **Reuse existing runtime wrappers** — don't reimplement what `Hiring`, `Signals`, `Discovery`, `DirectiveEmitter`, `PodRuntime` already do
4. **Test names from the plan** — see the plan's test name column
5. **Route convention**: new pages go in authenticated `live_session :authenticated` scope
6. **DB**: SQLite3 — no `FOR UPDATE`, no async task pools in tests
7. **ConnCase**: use `@moduletag :authenticated` for tests that need auth; use `log_in_user/2` for manual session setup
8. **Streams**: LV streams need an `:id` key on every item; use `Map.put(:id, ...)` when translating
9. **After each item**: run `mix test` full suite, confirm 0 failures, then move to next item
10. **Docs**: update `verification.md` and `capability_map.md` after each item lands

### Start

Begin with 3.1 (Capability Packs). Process each item in order through 3.7, then 7.10. For each, follow the DDTDD ritual: read the plan, discover the existing code, write the RED test, verify it fails, implement GREEN, run the full suite, update docs.

Proceed.
