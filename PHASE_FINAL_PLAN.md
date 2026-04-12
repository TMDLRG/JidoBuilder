# JidoBuilder — Final DD TDD Plan: Ship-Ready UAT

## Reality Check (honest baseline)

**What we have:** 104 tests, 0 failures, 34 routes, 5 umbrella apps.

**What's actually working end-to-end:**
- Agent hire/stop/list via Jido runtime (roster)
- Signal dispatch to running agents (assignments)
- Cron schedule create/cancel (schedules)
- All 5 StateOp types with preview (state-ops)
- Pod topology CRUD + hierarchy node linking
- Workflow DAG with D3 hook + step persistence
- Template library CRUD + editor
- Plugin/sensor enable/disable
- Workspace + partition CRUD
- Block editors for all 5 codegen types (action/agent/plugin/sensor/strategy)
- Auth (PBKDF2 login + session)
- Health/readyz/metrics endpoints
- SQLite WAL backup script

**What's smoke-only (heading renders, no real functionality):**
- `/directives` — hardcoded list, no composition form
- `/threads` — heading only
- `/memory` — heading only
- `/identity` — heading only
- `/glossary` — static term list (works but non-interactive)
- `/onboarding` — step wizard (works but doesn't actually do anything)
- `/debug` — reads DB but has no live ring-buffer or toggle
- `/error-policy` — heading only, no editor
- `/orphans` — heading only, no adoption workflow
- `/ejector` — form exists but no real file export
- `/pools` — static table, no config UI
- `/traces` — minimal DB read, no filtering

**Deferred capabilities:** 131 of 189 rows in verification.md (69%).

**Key Jido primitives NOT exposed in UI:**
1. Directive composition (11 types exist: Emit, Error, Spawn, SpawnAgent, AdoptChild, StopChild, Schedule, RunInstruction, Stop, Cron, CronCancel — only Cron/CronCancel have real UI)
2. Signal dispatch adapters (pid, pubsub, http, webhook, logger, bus, console)
3. Parent-child agent hierarchy operations (spawn child, adopt orphan, emit to parent)
4. Agent state validation (schema-based)
5. Discovery filtering (by category, tag, slug lookup)
6. Per-agent debug toggle + recent events ring buffer
7. Storage backend selection (ETS, File, Redis)
8. Worker pool configuration (poolboy integration)
9. Error policy selection (stop, retry, ignore, escalate)
10. Code export to standalone Elixir files

---

## Plan Structure

```
Phase A  — Make stubs real (convert 12 static pages to interactive)
Phase B  — Deep testing (replace smoke tests, add property tests)
Phase C  — Production build + hardening
Phase D  — UAT via Claude in Chrome (prove every flow for a layman)
Phase E  — Final verification + release sign-off
```

---

## Phase A — Make Stubs Real

### A.1 Directive Composer (`/directives`)

**Current:** Static list of 11 directive type names.
**Target:** Interactive form that composes any of the 11 directive types with their parameters, previews the struct, and optionally dispatches to a running agent.

**DDTDD:**
1. RED: Test that form renders all 11 type options, submitting "emit" type with signal_type + dispatch adapter produces a preview struct.
2. GREEN: Replace `directives/builder_live.ex` — add `DirectiveEmitter.from_config/1` call on submit, render preview JSON.
3. Tests: `test "compose emit directive previews struct"`, `test "compose cron directive"`, `test "compose spawn_agent directive"`, `test "compose stop directive"`.

**Key runtime call:** `DirectiveEmitter.from_config(%{kind: "emit", signal_type: "ping", ...})`

### A.2 Debug Panel (`/debug`)

**Current:** Reads DB errors/traces. No live toggle, no per-agent debug, no ring buffer.
**Target:** Toggle global debug on/off, show per-agent debug status, display recent events from `AgentServer.recent_events/2`.

**DDTDD:**
1. RED: Test toggle button changes debug state. Test agent list shows debug status.
2. GREEN: Add `handle_event("toggle_debug")` calling runtime debug facade. List running agents with their debug state. Add PubSub subscription for live event stream.
3. Tests: `test "toggle debug"`, `test "shows agent debug status"`.

### A.3 Error Policy Editor (`/error-policy`)

**Current:** Static list of 4 policy names.
**Target:** Form to select a policy per template, persists to template config.

**DDTDD:**
1. RED: Test selecting a policy and submitting persists to template config.
2. GREEN: Add form with template selector + policy radio buttons. On submit, update template config with `Templates.update_template/3`.
3. Tests: `test "select error policy persists to template config"`.

### A.4 Orphans + Adoption (`/orphans`)

**Current:** Heading only.
**Target:** List agents not attached to any pod. "Adopt" button links orphan to a topology via `Pods.create_node/2`.

**DDTDD:**
1. RED: Test lists orphan agents. Test adopt button creates pod node.
2. GREEN: Query agents NOT IN any pod_node. Add adopt form with topology selector.
3. Tests: `test "lists orphan agents"`, `test "adopt links agent to pod"`.

### A.5 Ejector (`/ejector`)

**Current:** Form exists but preview doesn't write to filesystem.
**Target:** Preview works (already does via CodegenTemplates.render). Add "Download" that sends the source as a file download.

**DDTDD:**
1. RED: Test preview renders defmodule source. Test download sends file.
2. GREEN: Preview already works. Add download via `push_event("download", %{filename: ..., content: ...})` + JS hook.
3. Tests: `test "preview renders source"`, `test "download event fires"`.

### A.6 Pools Configuration (`/pools`)

**Current:** Static table of default_pool/burst_pool.
**Target:** Form to update pool size/max_overflow. Persists to runtime config or template config.

**DDTDD:**
1. RED: Test form renders with current values. Test submit updates config.
2. GREEN: Add form with size/max_overflow inputs. Store in application env or template metadata.
3. Tests: `test "renders pool config"`, `test "update pool size"`.

### A.7 Traces Viewer (`/traces`)

**Current:** Minimal list of signals/directives with no filtering.
**Target:** Filter by signal_type, status, time range. Show detail on click.

**DDTDD:**
1. RED: Test filter form narrows results. Test shows signal/directive detail.
2. GREEN: Add filter form. Query `Observability.list_recent_signals/2` with filters. Render detail panel on row click.
3. Tests: `test "filter by signal type"`, `test "shows trace detail"`.

### A.8 Discovery Filters (`/skills`)

**Current:** Lists all actions from Discovery. No filter/search.
**Target:** Filter by category, tag. Click to show action detail (schema, description).

**DDTDD:**
1. RED: Test search input filters list. Test click shows action detail.
2. GREEN: Add search input with `phx-change` handler. Filter actions by name/category. Show detail panel.
3. Tests: `test "search filters actions"`, `test "click shows detail"`.

### A.9 Threads Explorer (`/threads`)

**Current:** Heading only.
**Target:** List agent threads from `Jido.Thread` if available; otherwise show a "create thread" form that persists to a `threads` table or agent metadata.

**DDTDD:**
1. RED: Test shows thread list (empty state). Test create form works.
2. GREEN: Since Jido.Thread is upstream, provide a builder-level thread tracker using agent metadata or a new schema table. Store thread entries as JSON in agent state.
3. Tests: `test "renders thread list"`, `test "create thread entry"`.

### A.10 Memory Spaces (`/memory`)

**Current:** Heading only.
**Target:** Display agent state as "memory." Allow creating named memory spaces (stored as template metadata keys).

**DDTDD:**
1. RED: Test shows memory spaces for workspace. Test create form adds space.
2. GREEN: Memory spaces are template metadata entries with a `memory_spaces` key. CRUD on that key.
3. Tests: `test "list memory spaces"`, `test "create memory space"`.

### A.11 Identity Profiles (`/identity`)

**Current:** Heading only.
**Target:** CRUD for agent identity profiles (name, persona, capabilities). Stored as template metadata.

**DDTDD:**
1. RED: Test shows profile list. Test create profile form.
2. GREEN: Profiles stored in template metadata under `identity` key.
3. Tests: `test "list profiles"`, `test "create profile"`.

### A.12 Onboarding Walkthrough (`/onboarding`)

**Current:** Step wizard with static text, steps don't do anything.
**Target:** Each step has a "Do it" button that navigates to the relevant page and pre-fills the form.

**DDTDD:**
1. RED: Test step 1 "Do it" navigates to `/workspaces`. Test step 3 navigates to `/roster`.
2. GREEN: Add navigation links per step. Use `push_navigate/2`.
3. Tests: `test "step 1 links to workspaces"`, `test "step 3 links to roster"`.

---

## Phase B — Deep Testing

### B.1 Replace Smoke Tests with Real Tests

For every test file that only checks "renders heading," add:
- At least one DB-write test (form submit → verify DB row)
- At least one interaction test (click event → verify state change)
- At least one negative test (invalid input → verify error message)

**Target:** Every test file has ≥ 3 tests with real assertions. Zero smoke-only files.

### B.2 Property Tests

Add StreamData property tests for:
- `StateOpAction.op_struct/2` — fuzz all 5 op types with random payloads
- `BlockSchema.valid?/1` — fuzz block maps with random fields
- `DirectiveEmitter.from_config/1` — fuzz all directive kinds

**Target:** 3 new property test files, 1000+ runs each.

### B.3 Integration Tests

Add tests that cross module boundaries:
- Roster.hire → Signals.cast → verify agent state changes
- Templates.create → CompileQueue.enqueue → verify generated module
- Pods.create_topology → PodRuntime.boot → verify runtime state

**Target:** 5 integration tests in a new `test/integration/` directory.

### B.4 E2E Playwright Coverage

Extend `e2e/tests/` with:
- `scenario_full_lifecycle.spec.ts` — workspace → template → hire → signal → schedule → stop → hibernate → thaw
- `scenario_codegen.spec.ts` — block editor → preview → compile → verify in skills
- `scenario_pod_orchestration.spec.ts` — create pod → add nodes → hierarchy view → orphan → adopt
- `scenario_settings.spec.ts` — create integration → add secret → verify redacted display
- `scenario_observability.spec.ts` — dispatch signals → verify traces → check debug panel

**Target:** 5 new Playwright spec files, all green.

---

## Phase C — Production Build + Hardening

### C.1 Docker Build Verification

```bash
cd builder
docker build -f Dockerfile -t jido-builder:rc ..
docker run -p 4000:4000 -e SECRET_KEY_BASE=$(mix phx.gen.secret) jido-builder:rc
curl http://localhost:4000/healthz   # expect 200
curl http://localhost:4000/readyz    # expect 200
curl http://localhost:4000/metrics   # expect prometheus text
```

### C.2 Release Smoke Test

```bash
MIX_ENV=prod mix release jido_builder
_build/prod/rel/jido_builder/bin/jido_builder start
# verify healthz, home page, login flow
```

### C.3 WAL Backup Verification

```bash
./infra/backup.sh jido_builder_dev.db /tmp/backup_test.db
sqlite3 /tmp/backup_test.db "PRAGMA integrity_check;"
# expect "ok"
```

### C.4 Security Audit

- Verify all authenticated routes redirect to `/login` when unauthenticated
- Verify `/healthz`, `/readyz`, `/metrics` are accessible without auth
- Verify secrets display as `[REDACTED]` in UI
- Verify Cloak encryption on secrets table (inspect raw SQLite)
- Verify Hammer rate limit on `/assignments` (11th request gets "Too many signals")

---

## Phase D — UAT via Claude in Chrome

**This is the proof.** Use `mcp__Claude_in_Chrome__*` tools to walk through every user scenario as a layman would, taking screenshots at every step.

### SCN-01: First-Time Onboarding
1. Navigate to `http://localhost:4000/login`
2. Log in with credentials
3. Navigate to `/onboarding`
4. Walk through all 4 steps
5. Verify each step links to the right page
6. **Screenshot:** onboarding flow complete

### SCN-02: Create Workspace + Template
1. Navigate to `/workspaces`
2. Create "My First Project" workspace
3. Navigate to `/templates`
4. Create a template "ChatBot" with name, slug, version, status
5. **Screenshot:** template created and visible in list

### SCN-03: Hire and Manage Agents
1. Navigate to `/roster`
2. Hire an agent "alpha-bot"
3. Verify agent appears in roster list
4. Navigate to `/agents/<id>`
5. Verify agent detail page shows state
6. Navigate back to `/roster`
7. Stop agent with confirmation modal
8. **Screenshot:** agent lifecycle complete

### SCN-04: Compose and Dispatch Signals
1. Navigate to `/roster`, hire an agent
2. Navigate to `/assignments/new`
3. Select the agent as target
4. Set signal type "ping", payload `{}`
5. Submit dispatch
6. Verify feedback panel shows "dispatched"
7. **Screenshot:** signal dispatched to running agent

### SCN-05: State Operations
1. Navigate to `/state-ops`
2. Test each of the 5 operations:
   - `set_state` with `{"x":1}` current + `{"y":2}` payload → verify merge
   - `replace_state` → verify wholesale replacement
   - `delete_keys` → verify key removal
   - `set_path` → verify nested path set
   - `delete_path` → verify nested path removal
3. **Screenshot:** all 5 ops produce correct results

### SCN-06: Build a Workflow
1. Navigate to `/workflows`
2. Verify DAG canvas renders
3. Save workflow with 2 steps (via hook event)
4. Verify steps persist (reload page, steps still there)
5. **Screenshot:** workflow with steps visible

### SCN-07: Schedule Cron Jobs
1. Navigate to `/schedules`
2. Create a schedule "Heartbeat" with cron `*/5 * * * *`
3. Verify schedule appears in list as "active"
4. Cancel the schedule
5. Verify status changes to "cancelled"
6. **Screenshot:** schedule created and cancelled

### SCN-08: Pod Orchestration
1. Navigate to `/teams`
2. Create pod "AlphaSquad" with strategy "round_robin"
3. Navigate to `/hierarchy`
4. Verify topology shows in tree
5. Add a node linking an agent instance
6. Verify node appears under topology
7. **Screenshot:** pod topology with node

### SCN-09: Capability Packs + Watchers
1. Navigate to `/capability-packs`
2. Verify plugins list for workspace
3. Disable a plugin → verify "disabled" label
4. Navigate to `/watchers`
5. Verify sensors list
6. **Screenshot:** plugins and sensors managed

### SCN-10: Block Editor + Code Generation
1. Navigate to `/blocks`
2. Validate a block definition (type: action, module: MyApp.Ping, name: ping)
3. Navigate to `/editor/action`
4. Preview source for an action
5. Verify `defmodule MyApp.Ping` appears in preview
6. Navigate to `/ejector`
7. Export the same block
8. **Screenshot:** generated Elixir source visible

### SCN-11: Compose Directives
1. Navigate to `/directives`
2. Select "emit" directive type
3. Fill signal_type "alert", dispatch adapter
4. Preview the directive struct
5. Select "cron" directive type
6. Fill cron expression, message
7. Preview the cron directive
8. **Screenshot:** directive composition for 2+ types

### SCN-12: Settings + Secrets
1. Navigate to `/settings`
2. Verify integrations section renders
3. Add a secret "API_KEY" with value "sk-test"
4. Verify secret appears with `[REDACTED]` value
5. **Screenshot:** secret stored and redacted

### SCN-13: Audit Trail
1. Perform several operations (hire, stop, create template)
2. Navigate to `/audit`
3. Verify audit events show actor, action, timestamp
4. **Screenshot:** audit trail with real events

### SCN-14: Debug + Observability
1. Navigate to `/debug`
2. Verify error/trace sections render
3. Navigate to `/traces`
4. Verify signal/directive trace log
5. **Screenshot:** observability views

### SCN-15: Full End-to-End Journey
1. Login → Onboarding → Create Workspace → Create Template
2. Add plugins + sensors to template
3. Hire agent from roster
4. Dispatch signal via assignments
5. View agent detail + state
6. Create schedule
7. Build workflow with steps
8. Create pod, add agent to pod
9. View audit trail
10. Hibernate agent → View in vault
11. **Screenshot sequence:** complete journey from zero to running agent system

---

## Phase E — Final Verification + Release Sign-Off

### E.1 Test Suite
```bash
cd builder && mix test
# Expect: ≥ 140 tests, 0 failures
```

### E.2 Verification Matrix Cleanup
- Walk every row in `verification.md`
- Remove contradictions (duplicate rows with different statuses)
- Every "done" row must have a test name or screenshot reference
- Every remaining "deferred" must have a clear reason

### E.3 Capability Map Sync
- `capability_map.md` matches `verification.md` exactly
- No orphaned entries

### E.4 Release Checklist
Update `builder/docs/release_checklist.md`:
- [ ] `mix test` → 0 failures
- [ ] `mix credo --strict` → 0 issues (or known waivers)
- [ ] `mix dialyzer` → 0 warnings (or known waivers)
- [ ] Docker build succeeds
- [ ] Docker run serves `/healthz` 200
- [ ] All 15 UAT scenarios pass via Chrome automation
- [ ] Playwright e2e suite green
- [ ] WAL backup integrity check passes
- [ ] All secrets display as `[REDACTED]` in UI
- [ ] Rate limit enforced on `/assignments`
- [ ] Audit trail captures all user actions

### E.5 Post-Build Audit Report
Append to `builder/docs/post_build_audit_2026-04-11.md`:
- Phase 3-6 completion evidence
- UAT scenario results with screenshot references
- Test count progression: 39 → 67 → 104 → final
- Verification matrix final tally
- Ship/No-Ship verdict per GAP-MVP item

---

## Success Criteria

The build is **Ship** when:

1. **Every nav item** in the app shell has a working, interactive page (not just a heading)
2. **Every Jido primitive** accessible via `Jido.*` public API has a corresponding UI surface
3. A **non-developer** can walk SCN-15 (full journey) without touching a terminal
4. **UAT screenshots** prove every scenario works in a real browser
5. **Test suite** has 0 failures and 0 smoke-only files
6. **Docker image** builds and serves the app from cold start
7. **Audit trail** captures every user action with actor + timestamp

---

## Estimated Work

| Phase | Items | Est. Tests Added |
|---|---|---|
| A (stubs → real) | 12 LV upgrades | ~30 |
| B (deep testing) | Smoke replacement + properties + integration + e2e | ~50 |
| C (production) | Docker + release + security audit | ~5 |
| D (UAT Chrome) | 15 scenarios | 0 (manual proof) |
| E (verification) | Doc cleanup + sign-off | 0 |
| **Total** | | **~85 new tests → ~189+ total** |
