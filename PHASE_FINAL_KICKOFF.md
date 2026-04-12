# Final Phase Kickoff Prompt

Paste everything below into a new Claude Code chat.

---

## Context

You are finishing the phased DDTDD implementation of **JidoBuilder**, a no-code Phoenix LiveView UI for the Jido Elixir agent framework. The canonical plan lives at `PHASE_FINAL_PLAN.md` in the repo root.

### Current state

- **104 tests, 0 failures** across the umbrella at `builder/`
- **34 LiveView routes** in the authenticated scope
- **Phases 0–6 + security interleaves (7.3–7.14)** are committed
- Umbrella apps: `jido_builder_core` (Ecto/SQLite3), `jido_builder_runtime` (Jido lifecycle), `jido_builder_codegen` (template rendering), `jido_builder_generated` (output), `jido_builder_web` (Phoenix LV)

### The problem

An honest audit reveals that **12 of the 34 route pages are smoke-only stubs** — they render a heading but have zero interactive functionality. 131 of 189 capabilities in `verification.md` are still marked "deferred." The core agent lifecycle works (hire/stop/signal/state-ops/cron/workflow/pods), but:

1. **Directive composition** — 11 directive types exist in Jido but only Cron/CronCancel have real UI forms. The `/directives` page is a hardcoded list with no compose form.
2. **Debug panel** — reads DB but has no live ring-buffer toggle or per-agent debug.
3. **Error policy, Orphans+Adoption, Ejector, Pools, Traces** — heading-only stubs.
4. **Threads, Memory, Identity** — heading-only Phase 6 stubs.
5. **Onboarding** — step wizard that doesn't actually navigate anywhere useful.
6. **Discovery filters** — `/skills` lists actions but has no search/filter/detail.
7. **37% of tests are smoke-only** (assert heading renders, nothing else).

### What Jido actually provides (upstream primitives the Builder must expose)

- **11 Directive types:** Emit, Error, Spawn, SpawnAgent, AdoptChild, StopChild, Schedule, RunInstruction, Stop, Cron, CronCancel — with helper constructors in `Jido.Agent.Directive`
- **5 StateOp types:** SetState, ReplaceState, DeleteKeys, SetPath, DeletePath
- **Discovery API:** list_actions/sensors/plugins/agents with filter by category, tag; get_by_slug; refresh; catalog
- **AgentServer:** call/cast, state, recent_events, set_debug — per-agent runtime ops
- **Signal dispatch adapters:** pid, pubsub, http, webhook, logger, bus, console, noop
- **Parent-child hierarchy:** SpawnAgent → parent tracking → emit_to_parent → orphan detection → AdoptChild
- **Storage backends:** ETS, File, Redis
- **Worker pools:** poolboy integration with size/max_overflow
- **Existing runtime wrappers** (already in builder): `Discovery.list_actions/1`, `Hiring.{start,stop,list,count,whereis}`, `Signals.{new,call,cast}`, `DirectiveEmitter.from_config/1`, `PodRuntime.boot/2`, `SensorHost.start_link/1`, `StateOpAction.op_struct/2`

### Architecture quick-reference

- **Auth:** `UserAuth` plug + `on_mount :ensure_authenticated`; `/healthz`, `/readyz`, `/metrics` bypass auth
- **Roster:** `Roster.hire/3` → `Hiring.start/3` → `Jido.start_agent/3`
- **PubSub topics:** `EventBus.workspace_activity_topic/1`, `agent_topic/2`, `workflow_topic/2`
- **DB:** SQLite3 — no `FOR UPDATE`, no `Task.async_stream` in sandbox tests
- **ConnCase:** `@moduletag :authenticated` auto-logs-in; `log_in_user/2` for manual
- **Codegen:** `CompileQueue.enqueue/2` → validate → write → compile → refresh → audit → rollback
- **Streams:** LV streams need `:id` key on every item

## Your task: Execute PHASE_FINAL_PLAN.md

Read `PHASE_FINAL_PLAN.md` for the full spec. Execute in order:

**Phase A** — Make 12 stub pages real. For each, follow DDTDD: write RED test, verify failure, implement GREEN, run full suite. Start with A.1 (Directive Composer) through A.12 (Onboarding links).

**Phase B** — Replace all smoke-only tests with real interaction tests. Add property tests for StateOpAction, BlockSchema, DirectiveEmitter. Add 5 integration tests. Extend Playwright e2e.

**Phase C** — Verify Docker build, release, WAL backup, security audit.

**Phase D** — Execute all 15 UAT scenarios using Claude in Chrome (`mcp__Claude_in_Chrome__*` tools). Navigate each page, fill forms, verify results, take screenshots as evidence.

**Phase E** — Clean up verification.md contradictions, sync capability_map.md, update release_checklist.md, write final audit verdict.

### Rules (same as all prior phases)

1. **DDTDD per item**: Discovery → RED test → verify RED → GREEN → REFACTOR → VALIDATE → DONE
2. **Reuse existing runtime wrappers** — `Hiring`, `Signals`, `Discovery`, `DirectiveEmitter`, `PodRuntime`, `StateOpAction`, `Observability`
3. **Test names from the plan** — see PHASE_FINAL_PLAN.md test descriptions
4. **Route convention**: all pages in authenticated `live_session :authenticated` scope
5. **DB**: SQLite3 — no `FOR UPDATE`, no async task pools in tests
6. **ConnCase**: `@moduletag :authenticated` for tests needing auth
7. **After each item**: `mix test` full suite, 0 failures, then next item
8. **Docs**: update `verification.md` and `capability_map.md` after each phase
9. **Be honest**: if a capability can't be implemented because the upstream Jido API doesn't support it, mark it as "deferred — upstream gap" with a clear reason, don't fake it with a heading-only page

### Start

Begin with Phase A, item A.1 (Directive Composer). Process each item in order. For each, follow DDTDD: read the plan, discover existing code, write the RED test, verify it fails, implement GREEN, run the full suite.

Proceed.
