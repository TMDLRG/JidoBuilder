# Builder DDTDD Execution Plan
## From Audit Verdict (No-Ship) to Production-Ready Solution

**Source of truth:** [`BUILDER_PLAN.md`](../../BUILDER_PLAN.md)
**Audit basis:** [`builder/docs/post_build_audit_2026-04-11.md`](post_build_audit_2026-04-11.md)
**Gap register:** [`builder/docs/next_steps.md`](next_steps.md) (`GAP-MVP-001` → `GAP-MVP-018`)
**Verification matrix:** [`builder/docs/verification.md`](verification.md)

---

## 0. Methodology — DDTDD (mandatory for every work item)

Every work item below MUST follow this seven-step ritual. **No code is committed without all seven steps proven in the commit message.**

| Step | Phase | What you do | Evidence required |
|---|---|---|---|
| 1 | **DISCOVERY** | Read the upstream Jido files relevant to the capability. Write down the exact function arity, return shape, and side effect for every Jido API you intend to call. | A `discovery:` block in the work-item branch (commit 1) listing each `lib/jido/...` file you read and each function/return shape you depend on |
| 2 | **RED** | Write the failing test FIRST. The test must encode the operator-visible outcome (a button click, a stream entry, a DB row, an audit event, a state transition), not an internal helper. | The commit message says `RED:` and includes the test file path + the specific assertion |
| 3 | **VERIFY** | Run the test. Confirm it fails for the **right** reason — i.e. the assertion fires, not a compile error or a missing import. If it errors instead of failing, fix the test until it cleanly fails on the assertion. | The commit message includes the failing assertion line from `mix test` output |
| 4 | **GREEN** | Write the minimum code that makes the test pass. Resist scope creep. If you find another bug, file it as a new work item — do NOT fix it in this commit. | Commit 2: `GREEN:` plus the modules/files that changed |
| 5 | **REFACTOR** | Clean up only what was just written. Re-run the test to prove green is preserved. | Commit 3 (optional): `REFACTOR:` |
| 6 | **VALIDATE** | Run the full umbrella `mix test`. If a Tier-A or Tier-B work item, also run the relevant Playwright spec. Walk the UI manually and capture the screen state. | Commit message includes `validate: mix test green (NN tests, 0 failures)` and screenshot path under `builder/docs/evidence/` |
| 7 | **DONE** | Update `builder/docs/verification.md` (status + confidence), `builder/docs/capability_map.md`, and (if shipping a UI surface) `builder/docs/scenario_certification.md`. Mark the GAP-MVP-* row as resolved in `next_steps.md` if the entire gap is now closed. | The commit message includes `done: verification row updated, GAP-MVP-XXX closed` |

**Hard rule: if the test passes on the first run before you wrote any GREEN code, the test is wrong. Throw it away and write a real one.**

---

## 0.5 Phase 0 Closure Marker

**Phase 0 closed on 2026-04-12.**

Baseline after closure: 24 tests across five umbrella apps, 0
failures. After 0.9 through 0.15 land, the baseline will be 27
tests, 0 failures (new injection test + two health controller
tests). The full Phase 0 work-item trail:

| Item | Fix | PR |
|---|---|---|
| 0.1 | ConnCase loading via `elixirc_paths(:test)` + `~p` sigil via `verified_routes/0` | #20, #21 |
| 0.2 | Sandbox ownership collision (runtime + web tests) | #22 |
| 0.2.1 | Test `secret_key_base` lengthened to 64 bytes | #23 |
| 0.2.1a | `:lazy_html` added as web test dep | #24 |
| 0.2.1b | 404 test aligned with rendered-response behavior | #25 |
| 0.2.2 | Seed workspace fixture for IntegrationRuntimeTest | #26 |
| 0.3 | Redaction test expects string keys after Cloak JSON round-trip | #27 |
| 0.4 | `Audit.log/4` uses subject's own id when subject is a Workspace | #28 |
| 0.5 | Codegen action template emits `use Jido.Action` | #28 |
| 0.6 | `FileWriter.resolve_path/1` normalizes root via `Path.expand/1` (Windows fix) | #28 |
| 0.7 | Rename `:jido_builder` OTP config to `:jido_builder_runtime` | #28 |
| 0.8 | CompileQueue rollback on compiler failure | #29 |
| 0.9 | Action template `@moduledoc` hardened via `inspect/1` | this batch |
| 0.10 | Scrubbed remaining `:jido_builder` doc references | this batch |
| 0.11 | `config/runtime.exs` for 12-factor prod secrets | this batch |
| 0.12 | `:releases` config added to umbrella `mix.exs` | this batch |
| 0.13 | `/healthz` and `/readyz` endpoints | this batch |
| 0.14 | Multi-stage Dockerfile (Alpine, Podman-compatible) | this batch |
| 0.15 | This closure marker | this batch |

**Handoff:** work items after 0.15 pass to Claude Code in a new
chat. Phases 1-6 (feature surfaces) and the remaining Phase 7
items (7.3 Cloak rotation, 7.5 codegen sandbox threat-model,
7.6 EEx property fuzzing, 7.10-7.14 operations) remain.

---

## 1. Read-First Inventory (the contracts you must obey)

Before writing any code, you MUST be able to answer "where does this live in upstream Jido?" for every primitive in the work item. The plan in `BUILDER_PLAN.md` §0.3 is your map. The actual sources are:

| Capability area | Upstream files (read-only) |
|---|---|
| Top-level lifecycle | `lib/jido.ex`, `lib/jido/agent.ex` |
| Agent server | `lib/jido/agent_server.ex`, `lib/jido/agent_server/signal_router.ex`, `lib/jido/agent_server/error_policy.ex` |
| Directives | `lib/jido/agent/directive.ex`, `lib/jido/agent/directive/cron.ex`, `lib/jido/agent/directive/cron_cancel.ex` |
| State ops | `lib/jido/agent/state_op.ex` |
| Strategies | `lib/jido/agent/strategy.ex`, `lib/jido/agent/strategy/direct.ex`, `lib/jido/agent/strategy/fsm.ex` |
| Discovery | `lib/jido/discovery.ex` |
| Signals | `deps/jido_signal/lib/...` (Hex), specifically `Jido.Signal.new!/2,3` |
| Built-in actions | `lib/jido/actions/control/*`, `lib/jido/actions/lifecycle/*`, `lib/jido/actions/scheduling/*`, `lib/jido/actions/status/*` |
| Pods | `lib/jido/pod.ex`, `lib/jido/pod/topology.ex`, `lib/jido/pod/actions/*` |
| Plugins | `lib/jido/plugin.ex`, `lib/jido/plugin/spec.ex`, `lib/jido/plugin/instance.ex` |
| Sensors | `lib/jido/sensor.ex`, `lib/jido/sensor/runtime.ex`, `lib/jido/sensors/*` |
| Storage / persistence | `lib/jido/storage/*`, `lib/jido/persist.ex`, `lib/jido/agent/instance_manager.ex` |
| Threads / memory / identity | `lib/jido/thread/*`, `lib/jido/memory/*`, `lib/jido/identity/*` |
| Observability | `lib/jido/observe.ex`, `lib/jido/observe/*`, `lib/jido/tracing/*`, `lib/jido/debug.ex` |
| Scheduling | `lib/jido/scheduler.ex`, `lib/jido/scheduler/job.ex` |
| Awaits | `lib/jido/await.ex` |
| Worker pools | `lib/jido/agent/worker_pool.ex` |
| Igniter helpers (codegen reuse) | `lib/jido/igniter/*` |

**Discovery deliverable per work item:** a paragraph in the work-item branch that lists "I read X. The function I depend on is `Foo.bar/2` which returns `{:ok, %Y{}} \| {:error, %Z{}}` with side effect *…*". Cite line numbers.

---

## 2. Operating rules (non-negotiable)

| # | Rule |
|---|---|
| R1 | **Zero fiction.** A LiveView event handler that does not call a real `JidoBuilderRuntime.*` function and produce a real DB write or PubSub broadcast must not exist. If you can't wire it, render the "Unavailable in MVP — `<gap-id>`" card per BUILDER_PLAN §3.5. |
| R2 | **Test-first, always.** No file under `apps/*/lib/` is created or modified without a failing test pinned to it first. If the failure is environmental (missing dep, missing config), fix the environment and re-state the failure. |
| R3 | **One work item = one PR.** Each PR closes at most one Tier slice or one bug. Sweeping refactors are forbidden. |
| R4 | **Conventional commits.** `feat(scope):`, `fix(scope):`, `test(scope):`, `docs(scope):`, `chore(scope):`, `refactor(scope):`. Scope is one of `core`, `runtime`, `codegen`, `web`, `infra`, `docs`. |
| R5 | **Audit every write.** Every context-module write goes through `JidoBuilderCore.Observability.insert_with_audit/4` (or equivalent) so a row lands in `audit_events`. |
| R6 | **No outbound HTTP** unless the user has wired an integration in Settings. |
| R7 | **No `Code.eval_string` on user input. Ever.** Codegen composes EEx templates from curated blocks only. |
| R8 | **Never edit upstream Jido.** `lib/jido/`, `lib/jido.ex`, top-level `mix.exs`, and `guides/` are read-only. All your code is under `builder/`. |
| R9 | **Production-mode awareness.** A feature is not done until it works under `MIX_ENV=prod` with a real release. |
| R10 | **Layman first.** Plain language before jargon. Every error state names the problem, the cause, and the next step. |

---

## 3. Phase 0 — Stabilize the Baseline

**Goal:** the current `mix test` baseline runs cleanly. No new features. Just remove the friction blocking everything else.

The local baseline (Erlang/OTP 28.4.2 + Elixir 1.19.5) currently shows **5 test failures + 1 suite blocked** (see commit `e6108e9` for compile-enabling fixes, and the post-baseline notes below). Each item is a separate work item.

### Work item 0.1 — Web test suite cannot compile (`ConnCase` not loaded)
- **Symptom:** `mix test` for `jido_builder_web` errors with `module JidoBuilderWeb.ConnCase is not loaded and could not be found`. The compiler warning explicitly says `test/support/conn_case.ex` does not match any configured `:test_load_filters`.
- **Discovery:** read `apps/jido_builder_web/mix.exs` and look for `elixirc_paths`, `test_paths`, and the `:test_load_filters` setting on `Mix.Project`. Also check the umbrella root `mix.exs`.
- **RED:** add a no-op test under `apps/jido_builder_web/test/support/conn_case_loading_test.exs` that simply does `use JidoBuilderWeb.ConnCase, async: false` and asserts `true == true`. It must currently fail to compile.
- **GREEN:** add `elixirc_paths(:test) = ["lib", "test/support"]` (and a private function) to `apps/jido_builder_web/mix.exs`, mirroring the standard Phoenix-LV layout.
- **VALIDATE:** `cd builder && mix test --only conn_case_loading` returns 1 test, 0 failures.
- **Acceptance:** the existing `apps/jido_builder_web/test/jido_builder_web_test.exs` (which uses `JidoBuilderWeb.ConnCase`) now also compiles cleanly.
- **Closes:** N/A (environment fix, not a GAP).

### Work item 0.2 — Integration test missing Sandbox checkout
- **Symptom:** `apps/jido_builder_runtime/test/integration_runtime_test.exs:14` raises `DBConnection.OwnershipError` when `Hiring.start/3` calls `Observability.insert_with_audit/4`.
- **Discovery:** read `apps/jido_builder_runtime/lib/jido_builder_runtime/hiring.ex`. Confirm it writes to `signals_log`/`audit_events`. Read `apps/jido_builder_core/lib/jido_builder_core/repo.ex` to confirm pool config.
- **RED:** the test is already failing — that *is* the RED state. Quote the assertion in your branch notes.
- **GREEN:** in `setup_all` of `IntegrationRuntimeTest`, call `Ecto.Adapters.SQL.Sandbox.checkout(JidoBuilderCore.Repo)` and `Sandbox.mode({:shared, self()})`. Document why `setup_all` (not `setup`) — the runtime supervisor processes need access for the entire test module.
- **VALIDATE:** `mix test apps/jido_builder_runtime/test/integration_runtime_test.exs` is green.
- **Closes:** N/A (test bug, not a GAP).

### Work item 0.3 — `JidoBuilderCore.SecurityTest` redaction key mismatch
- **Symptom:** `security_test.exs:82` expects `%{api_key: "[REDACTED]", options: [%{token: "[REDACTED]"}]}` but gets string keys.
- **Discovery:** read `apps/jido_builder_core/lib/jido_builder_core/security/integration.ex` and the redaction helper. Identify whether redaction returns the original map shape or a JSON-decoded map.
- **RED:** the failing test IS RED. Document the assertion.
- **GREEN:** decide one canonical redaction shape (recommend: preserve atom keys to match the schema). Fix the redactor to walk the input map without round-tripping through JSON. **Do not** change the test to match the bug.
- **VALIDATE:** `mix test apps/jido_builder_core/test/security_test.exs` green.
- **Closes:** part of `GAP-MVP-017` (configuration/redaction surface).

### Work item 0.4 — `SchemaAndContextTest` missing audit action
- **Symptom:** `schema_and_context_test.exs:43` expects `"agents.workspaces.create"` in the actions list but only sees `"workflows.create"`.
- **Discovery:** read `apps/jido_builder_core/lib/jido_builder_core/agents/workspaces.ex` (or wherever the workspaces context lives). Confirm the context exists and audit-emits.
- **RED:** failing assertion documented.
- **GREEN:** ensure the workspaces create flow emits an audit row with action `"agents.workspaces.create"`. Add the action constant if missing.
- **VALIDATE:** the test passes; manually verify with `mix run` that creating a workspace inserts an `audit_events` row with the correct action.
- **Closes:** prerequisite for `GAP-MVP-015` (workspace multi-tenancy).

### Work item 0.5 — Codegen template renders `@behaviour` instead of `use Jido.Action`
- **Symptom:** `apps/jido_builder_codegen/test/jido_builder_codegen_test.exs:25` expects `source =~ "use Jido.Action"` but template emits `@behaviour Jido.Action`.
- **Discovery:** read the upstream `lib/jido/action.ex` `__using__/1` macro. Confirm `use Jido.Action, name: ..., schema: ...` is the canonical pattern (it generates `name/0`, `description/0`, schema validation, etc. — `@behaviour` alone misses all of that).
- **RED:** test already failing.
- **GREEN:** edit `apps/jido_builder_codegen/priv/templates/action.ex.eex` to emit `use Jido.Action, name: "<%= @name %>", description: <%= inspect(@description) %>, schema: <%= inspect(@schema) %>` and keep the `def run/2` block.
- **VALIDATE:** the rendered source compiles when written into `jido_builder_generated`. The next work item (0.6) depends on this.
- **Closes:** part of `GAP-MVP-010` (block editor / compile path).

### Work item 0.6 — `CompileQueue.enqueue` rejects with `:path_outside_generated_lib` on Windows
- **Symptom:** `apps/jido_builder_codegen/test/jido_builder_codegen_test.exs:42` — the queue refuses the write with `:path_outside_generated_lib` even though the path is under `apps/jido_builder_generated/lib/`. Almost certainly a slash-direction comparison bug on Windows.
- **Discovery:** read `apps/jido_builder_codegen/lib/jido_builder_codegen/compile_queue.ex`. Find the path-allowlist check. Identify whether it uses raw string equality, `String.starts_with?`, or `Path.expand` + comparison.
- **RED:** failing test documented. Add a second test case with an absolute path containing forward slashes that should be accepted, to lock in cross-platform behavior.
- **GREEN:** normalize both the candidate path and the allowed prefix through `Path.expand/1` and compare with `Path.split/1` to avoid string-level slash mismatches. Reject only if the expanded candidate is not a descendant of the expanded `generated/lib` prefix.
- **VALIDATE:** test green on Windows AND on Linux (CI). Add a `@tag :os` regression case for both.
- **Closes:** part of `GAP-MVP-010`.

### Work item 0.7 — Bogus `config :jido_builder, ...` warning
- **Symptom:** every `mix` invocation emits `You have configured application :jido_builder in your configuration file, but the application is not available.`
- **Discovery:** `grep -n "config :jido_builder" builder/config/*.exs`. There is no `:jido_builder` OTP application — the Jido instance is owned by `:jido_builder_runtime`.
- **RED:** add a `mix compile --warnings-as-errors` smoke test in CI for the umbrella root.
- **GREEN:** rename `config :jido_builder, ...` blocks to `config :jido_builder_runtime, ...` and update `JidoBuilderRuntime.Jido` (`use Jido, otp_app: :jido_builder_runtime`).
- **VALIDATE:** clean `mix compile`, no warning. `mix test` still green.
- **Closes:** part of `GAP-MVP-017`.

**Phase 0 exit criteria:** `mix test` at the umbrella root runs cleanly with **0 failures**. Commit message at the end of Phase 0: `chore(builder): close phase 0 — green baseline established (NN tests, 0 failures)`.

---

## 4. Phase 1 — The Single Truth Path

**Audit citation:** Priority Fix Plan, Critical #2 — *"Implement the single truth path: Hire agent → assign signal → observe progress → stop agent entirely from UI."*

**Goal:** prove the entire stack (LiveView → context → runtime wrapper → upstream Jido → telemetry → PubSub → UI) is wired end-to-end on one happy path. No additional features. This is the demo-trust unlock.

### Work item 1.1 — Hire form actually hires (`GAP-MVP-001`)
- **Discovery:** read `lib/jido.ex` for `start_agent/3` arity and return shape. Read `apps/jido_builder_runtime/lib/jido_builder_runtime/hiring.ex` (already exists). Confirm it accepts a template-id + optional partition + display name.
- **RED:** add `apps/jido_builder_web/test/jido_builder_web/live/roster_hire_test.exs` that:
  1. Inserts a seed `agent_templates` row.
  2. Mounts the `RosterLive`.
  3. Submits the hire form via `render_submit/2`.
  4. Asserts (a) `Jido.list_agents(JidoBuilderRuntime.Jido)` includes the new agent id; (b) `agent_instances` table has a row with status `:running`; (c) `audit_events` has a `roster.hire` row; (d) the LiveView re-renders with the new row visible in the roster table.
- **GREEN:**
  - Replace the placeholder `roster_live.ex` with a real form (template picker, display name, partition, "Hire" button) and a roster table populated from `JidoBuilderCore.Agents.Roster.list/1`.
  - Implement `Roster.list/1` and `Roster.hire/2` context functions.
  - Wire `handle_event("hire", params, socket)` → `JidoBuilderRuntime.Hiring.start/3` → audit row → broadcast on `"roster"` topic → re-render.
- **VALIDATE:** Playwright `e2e/tests/hire_truth_path.spec.ts` — open `/roster`, fill the form, submit, expect a new row with status badge "Running", expect the activity stream to show `agent.started`. Take a screenshot under `builder/docs/evidence/phase1/01_hire.png`.
- **DONE:** mark `Start agent` and `List running agents` rows in `verification.md` as `done` confidence 5.

### Work item 1.2 — Assignments console actually dispatches a signal (`GAP-MVP-002`)
- **Discovery:** read `lib/jido/agent_server.ex` for `call/2,3` and `cast/2`. Read `apps/jido_builder_runtime/lib/jido_builder_runtime/signals.ex`. Read `lib/jido/signal.ex` for `new!/2,3`.
- **RED:** test under `apps/jido_builder_web/test/jido_builder_web/live/assignment_dispatch_test.exs` — start a hired agent (helper), open `/assignments/new`, pick the agent + signal type + JSON payload, submit, assert (a) `signals_log` row inserted, (b) PubSub broadcast on `"agent:<id>"`, (c) the agent state actually changed (read via `AgentServer.state/1`).
- **GREEN:** build the new LV at `apps/jido_builder_web/lib/jido_builder_web/live/assignments/new_live.ex`. Form fields: target agent (select from running agents), signal type (text), payload (textarea, JSON). On submit → `Signals.new/4` → `Signals.call/4` (or `cast/3`) → result feedback panel.
- **VALIDATE:** Playwright `e2e/tests/assignment_dispatch.spec.ts`. Screenshot to `evidence/phase1/02_assign.png`.
- **DONE:** mark `Sync signal send`, `Async signal send`, `Build CloudEvent signal` rows done.

### Work item 1.3 — Activity stream shows the action and its outcome (`GAP-MVP-007`)
- **Audit citation:** G-005 (observability not layman-operational).
- **Discovery:** read `apps/jido_builder_runtime/lib/jido_builder_runtime/telemetry_bridge.ex`. Confirm it attaches to `[:jido, :agent, :cmd, :start | :stop | :exception]` and broadcasts to `"activity:global"`. If it does not, add it.
- **RED:** `apps/jido_builder_web/test/jido_builder_web/live/dashboard_activity_test.exs` — fire a real `cmd/2` against an agent, assert the `DashboardLive` stream contains an entry with (a) plain-language label (`"Worker X completed task Y in 12ms"`, NOT `"agent.cmd.stop"`), (b) status icon, (c) link to the agent detail page.
- **GREEN:**
  - Add a `JidoBuilderCore.Observability.translate_event/1` function that maps every telemetry event to a `%{label, status, agent_link, ts}` tuple in plain language.
  - Update `dashboard_live.ex` and `agent_live.ex` to render translated rows.
  - Add a "next action" hint when status is `:error` (e.g., "Open the agent's debug panel").
- **VALIDATE:** screenshot showing real translated rows. `evidence/phase1/03_activity.png`.
- **DONE:** mark `Live telemetry stream`, `Per-agent events stream` rows done. Update `capability_map.md`.

### Work item 1.4 — Stop agent with confirmation (`GAP-MVP-001`)
- **Discovery:** read `lib/jido.ex` for `stop_agent/2`. Read `lib/jido/agent/directive.ex` for `Directive.stop/0,1`.
- **RED:** test that clicking "Stop" without confirming does nothing, and clicking "Stop" through the confirmation modal removes the agent from the roster, fires a `roster.stop` audit event, and broadcasts on `"roster"`.
- **GREEN:** add a confirmation modal to `roster_live.ex` with the exact copy `"Stop worker <name>? In-flight tasks (<count>) will be cancelled."` per BUILDER_PLAN §3.4. Wire `Hiring.stop/2`.
- **VALIDATE:** Playwright spec covering confirm-cancel + confirm-confirm. Screenshots.
- **DONE:** mark `Stop agent`, `Directive Stop` rows done.

### Work item 1.5 — End-to-end Phase 1 scenario certification
- **Discovery:** read the existing Playwright config in `e2e/playwright.config.ts`.
- **RED:** add `e2e/tests/scenario_truth_path.spec.ts` — a single test that walks the entire UI path: hire → assign → observe → stop. Initially it must fail because at least one step is missing (it isn't, by now, but the test pins reality).
- **GREEN:** if any glue is missing, add it. No new features.
- **VALIDATE:** the spec passes headlessly. Capture a screen recording at `evidence/phase1/05_truth_path.webm`.
- **DONE:** mark `SCN-01` (brief scenario 1) as `pass` in `scenario_certification.md` with the test name and timestamp.

**Phase 1 exit criteria:** the truth path runs in the UI with zero CLI involvement. The audit's #1 demo-trust risk is closed. Commit: `feat(web): close phase 1 — single truth path live`.

---

## 5. Phase 2 — Tier A Surfaces (rest of the vertical slice)

**Reference:** BUILDER_PLAN §3.3 Tier A. Phase 1 already covered Roster, Assignments, Activity (parts of items 4, 5, 6, 7). This phase finishes Tier A.

For each surface below: **one work item, DDTDD ritual, real wiring, real evidence, verification row updated.**

| # | Surface | LiveView module | Primary runtime call | Acceptance test name | Closes (gap) |
|---|---|---|---|---|---|
| 2.1 | App shell + nav + Cmd+K palette | `layouts/root.html.heex`, `command_palette_live.ex` | router + LV navigate | `e2e/tests/app_shell_navigation.spec.ts` | n/a |
| 2.2 | Home / Overview with KPIs | `home_live.ex` | `Jido.agent_count/1`, telemetry rollups | `home_kpi_live_test.exs` | `GAP-MVP-007` |
| 2.3 | Templates Library | `templates/index_live.ex` | `Templates.list/1` | `templates_index_test.exs` | prerequisite for `GAP-MVP-001` |
| 2.4 | Template Editor | `templates/edit_live.ex` | `Templates.upsert/2`, route editor | `template_editor_test.exs` | `GAP-MVP-002` |
| 2.5 | Agent Detail (state, controls) | `agent_live.ex` | `AgentServer.state/1`, `recent_events/2` | `agent_detail_state_test.exs` | `GAP-MVP-007` |
| 2.6 | Skills catalog (Discovery) | `skills/index_live.ex`, `skills/detail_live.ex` | `Discovery.list_actions/1`, `get_action_by_slug/1` | `skills_catalog_test.exs` | `GAP-MVP-003` |
| 2.7 | Work Styles picker | `work_styles/index_live.ex` | strategy enum + saved selection | `work_styles_pick_test.exs` | `GAP-MVP-010` (picker only; custom strategies later) |
| 2.8 | Directives Builder (all 11) | `directives/builder_live.ex` | `DirectiveEmitter.from_config/1` | `directives_builder_test.exs` (parameterized over the 11 kinds) | `GAP-MVP-002` |

**Per work item, the DDTDD ritual is the same as Phase 1.** For each:
- Discovery references upstream files.
- RED encodes the operator outcome.
- GREEN builds the LV + context glue.
- VALIDATE runs the spec + screenshot.
- DONE updates the verification matrix.

**Phase 2 exit criteria:** all 10 Tier A items in BUILDER_PLAN §3.3 are wired. `mix test` green. Tier A scenarios in `scenario_certification.md` marked `pass`.

---

## 6. Phase 3 — Tier B (Team Orchestration)

**Reference:** BUILDER_PLAN §3.3 Tier B + Audit Priority Fix Plan, High #1, #2, #3.

| # | Surface | Closes |
|---|---|---|
| 3.1 | Capability Packs (plugin browser + edit) | `GAP-MVP-008` |
| 3.2 | Watchers (sensor browser + heartbeat/bus configurator + sensor host wiring) | `GAP-MVP-008` |
| 3.3 | Teams / Pods MVP (create pod, add members, broadcast, observe fan-out) | `GAP-MVP-012` |
| 3.4 | Hierarchy view (parent/child tree, adopt orphan) | `GAP-MVP-009` |
| 3.5 | Playbooks / Workflow Builder MVP (per-step state, run, inspect) | `GAP-MVP-002` (workflow execution) |
| 3.6 | State Ops editor (all 5 ops) | `GAP-MVP-005` |
| 3.7 | Schedules MVP (cron create / cancel + scheduler runtime) | `GAP-MVP-006` |

Each item produces a Playwright spec under `e2e/tests/tier_b_<surface>.spec.ts` and a screenshot/video under `evidence/phase3/`.

**Phase 3 exit criteria:** `scenario_certification.md` SCN-09 (cron) and SCN-10 (pod broadcast) pass.

---

## 7. Phase 4 — Tier C (Operations and Trust)

**Reference:** BUILDER_PLAN §3.3 Tier C + Audit Priority Fix Plan, Critical #4 (Activity + Audit).

| # | Surface | Closes |
|---|---|---|
| 4.1 | Audit History (filter by actor/agent/time, immutable rows) | `GAP-MVP-007` |
| 4.2 | Vault (hibernate/thaw + adapter picker — ETS, File, Redis-optional) | `GAP-MVP-004` |
| 4.3 | Traces viewer (span-tree from `Jido.Tracing.Context`) | `GAP-MVP-007` |
| 4.4 | Pools (worker pool config + checkout on hire) | `GAP-MVP-014` |
| 4.5 | Settings / Integrations / Secrets (Cloak-encrypted CRUD) | `GAP-MVP-017` |
| 4.6 | Workspaces (partition CRUD + partition-scoped roster) | `GAP-MVP-015` |

**Phase 4 exit criteria:** SCN-07 (hibernate/thaw + partition move) passes.

---

## 8. Phase 5 — Tier D (Codegen Block Editors)

**Reference:** BUILDER_PLAN §4.5 + §3.3 Tier D.

| # | Surface | Closes |
|---|---|---|
| 5.1 | Block library + manifest validator | `GAP-MVP-010` |
| 5.2 | Compile pipeline hardened (rollback on failure, sandbox check, Discovery refresh) | `GAP-MVP-010` |
| 5.3 | Block Editor — Action | `GAP-MVP-010` |
| 5.4 | Block Editor — Sensor | `GAP-MVP-010` |
| 5.5 | Block Editor — Plugin | `GAP-MVP-008` (custom plugin path) |
| 5.6 | Block Editor — Strategy | `GAP-MVP-010` |
| 5.7 | FSM Designer | `GAP-MVP-010` |
| 5.8 | Ejector (export-as-Elixir bundles) | `GAP-MVP-018` |

**Security gate before this phase:** the codegen sandbox must pass an explicit threat-model review (see Phase 7 §10.2). No block editor LV is wired until the sandbox check is hardened.

**Phase 5 exit criteria:** SCN-05 (custom action visible in Skills) passes.

---

## 9. Phase 6 — Tier E (Polish)

| # | Surface | Closes |
|---|---|---|
| 6.1 | Threads explorer | `GAP-MVP-013` |
| 6.2 | Memory spaces | `GAP-MVP-013` |
| 6.3 | Identity profiles | `GAP-MVP-013` |
| 6.4 | Glossary | n/a |
| 6.5 | Onboarding walkthrough | required for layman-usable verdict |
| 6.6 | Debug panel (live ring buffer) | `GAP-MVP-007` |
| 6.7 | Error Policy editor | `GAP-MVP-011` |
| 6.8 | Orphans & Adoption view | `GAP-MVP-009` |
| 6.9 | Accessibility audit (axe-core) | non-functional requirement |

**Phase 6 exit criteria:** every nav item in BUILDER_PLAN §3.1 has a working screen. SCN-06 and SCN-08 pass.

---

## 10. Phase 7 — Production Readiness

**Goal:** the umbrella ships as a real product, not just `mix phx.server` on a developer laptop.

### 10.1 Release plumbing

#### 7.1 — `config/runtime.exs` (12-factor secrets)
- **Discovery:** read Phoenix release docs (`mix phx.gen.release` template), Cloak vault start sequence, and current `config/prod.exs`.
- **RED:** add `apps/jido_builder_web/test/release_config_test.exs` that boots the umbrella under `MIX_ENV=prod` with required env vars (`SECRET_KEY_BASE`, `DATABASE_PATH`, `JIDO_BUILDER_CLOAK_KEY`, `PHX_HOST`, `PORT`) and asserts the supervision tree comes up.
- **GREEN:** create `builder/config/runtime.exs` modelled on the standard Phoenix template. Move `prod`-time secrets out of `prod.exs`.
- **VALIDATE:** `MIX_ENV=prod mix release jido_builder` builds without errors. `_build/prod/rel/jido_builder/bin/jido_builder eval ":init.get_status()"` returns `{:started, :started}`.
- **Closes:** prerequisite for Docker.

#### 7.2 — `mix release` config in `mix.exs`
- **Discovery:** read the umbrella `mix.exs`. Identify which app owns the release (must be `jido_builder_web` since it boots the endpoint).
- **RED:** add a CI job `release-smoke` that runs `mix release --overwrite` and exits non-zero on failure. Locally, fail if `_build/prod/rel/jido_builder/bin/jido_builder` does not exist.
- **GREEN:** add a `releases:` keyword to the umbrella `mix.exs` declaring `jido_builder` with the umbrella applications listed and an explicit `cookie:` env var.
- **VALIDATE:** the release boots and serves `GET /healthz` (added in 7.4) with HTTP 200.
- **Closes:** prerequisite for Docker.

#### 7.3 — `JIDO_BUILDER_CLOAK_KEY` rotation tooling
- **Discovery:** read Cloak.Ecto `Migrator` docs.
- **RED:** test that adding a second cipher (`AES.GCM.V2`) makes new writes go to V2 while reads still decode V1.
- **GREEN:** wire `Cloak.Ciphers.AES.GCM` with `default: V2` and `legacy: [V1]`. Add `mix jido_builder.rotate_secrets` Mix task that walks every encrypted column and re-encrypts with V2.
- **VALIDATE:** integration test rotates a fixture row.
- **Closes:** part of `GAP-MVP-017`.

#### 7.4 — Health endpoints (`/healthz`, `/readyz`)
- **Discovery:** read Bandit + Phoenix Plug docs.
- **RED:** `apps/jido_builder_web/test/health_endpoint_test.exs` — `GET /healthz` returns 200 always; `GET /readyz` returns 200 only when Repo + Jido instance + PubSub are up, 503 otherwise.
- **GREEN:** add `JidoBuilderWeb.HealthController` and route entries.
- **VALIDATE:** kill the Repo, hit `/readyz`, expect 503; bring it back, expect 200.
- **Closes:** prerequisite for container orchestration.

### 10.2 Codegen sandbox hardening (security gate)

#### 7.5 — Path-allowlist hardening
- **Discovery:** re-read work item 0.6 plus `apps/jido_builder_codegen/lib/jido_builder_codegen/compile_queue.ex`. Identify every place a file write happens.
- **RED:** add tests that explicitly try to write to `lib/jido/`, `apps/jido_builder_core/lib/`, `..` traversals, and absolute paths outside the umbrella. All must be rejected.
- **GREEN:** centralize all writes through a `CompileQueue.safe_write/2` function that resolves the absolute path and rejects anything outside `apps/jido_builder_generated/lib/`. No bypass.
- **VALIDATE:** the rejection tests pass on Linux + Windows.
- **Closes:** prerequisite for Phase 5 (block editors) ship.

#### 7.6 — EEx template audit
- **Discovery:** list every template under `apps/jido_builder_codegen/priv/templates/` and trace which assigns are user-controllable.
- **RED:** add property-based tests (StreamData) that fuzz user-controllable assigns with shell metachars, Elixir injection attempts (`#{}`, `\""`), and confirm none escape the template's `inspect/1` boundary.
- **GREEN:** ensure every user assign is rendered through `inspect/1` or a strict whitelist (block kind, slug, type). No raw interpolation.
- **VALIDATE:** fuzz tests green for at least 1000 iterations.
- **Closes:** part of `GAP-MVP-010`.

### 10.3 Containerization (Docker + Podman)

#### 7.7 — Multi-stage `Dockerfile`
- **Discovery:** read [Phoenix's official deployment guide](https://hexdocs.pm/phoenix/releases.html). Confirm Erlang/OTP 28 + Elixir 1.19 base image availability on `hexpm/elixir:1.19.5-erlang-28.4.2-alpine-3.20`.
- **RED:** add `infra/Dockerfile.test` (or a `docker-build` CI job) that runs `docker build` and exits non-zero on failure.
- **GREEN:** create `builder/Dockerfile` (or `infra/Dockerfile`) with two stages:
  - **Stage `build`:** copies repo, runs `mix deps.get`, `mix assets.deploy` (Phase 7 prerequisite — wire tailwind+esbuild for prod), `mix release jido_builder`.
  - **Stage `runtime`:** alpine base + `libstdc++ libgcc openssl ncurses-libs sqlite`. Copies `_build/prod/rel/jido_builder/`. `EXPOSE 4000`. `VOLUME /var/lib/jido_builder`. Non-root user `app:app` with UID 1000. `CMD ["/app/bin/jido_builder", "start"]`.
- **VALIDATE:** `docker build -f builder/Dockerfile -t jido-builder:test .` succeeds. `docker run --rm -e SECRET_KEY_BASE=... -e JIDO_BUILDER_CLOAK_KEY=... -p 4000:4000 jido-builder:test` boots and `curl http://localhost:4000/healthz` returns 200.
- **Closes:** the audit's G-008 (environment fragility).

#### 7.8 — Podman compatibility
- **Discovery:** verify the OCI image is rootless-compatible. Document the `--userns=keep-id` flag for rootless Podman.
- **RED:** add `infra/podman-smoke.sh` that runs `podman build` and `podman run` against the same Dockerfile.
- **GREEN:** ensure the image's `USER` directive uses a numeric UID and the volume mount path `chown`s correctly. No SELinux or runtime-specific tweaks should be required.
- **VALIDATE:** the smoke script boots the container under rootless Podman and `curl /healthz` returns 200.
- **Closes:** explicit Podman support (audit G-008).

#### 7.9 — `docker-compose.yml` / `compose.yaml`
- **Discovery:** confirm whether the user wants Redis enabled by default (it's optional per `JIDO_BUILDER_REDIS_ENABLED`).
- **RED:** none — this is config.
- **GREEN:** create `infra/compose.yaml` with one service (`builder`), one volume (`/var/lib/jido_builder`), env vars from `.env`, and an optional `redis` profile (`--profile redis`).
- **VALIDATE:** `docker compose up -d` boots; `curl http://localhost:4000` returns the home page.

### 10.4 Operations

| # | Item | Acceptance |
|---|---|---|
| 7.10 | SQLite WAL-aware backup script (`infra/backup.sh`) | restores into a fresh container and the test suite passes against the restored DB |
| 7.11 | Structured logger (`Logger` JSON formatter for prod) | `docker logs builder` emits one JSON object per line; sample line includes `level`, `time`, `msg`, `agent_id?` |
| 7.12 | Telemetry export (Prometheus on `/metrics` via `telemetry_metrics_prometheus`) | `curl /metrics` returns the four `phoenix_*` summaries from `JidoBuilderWeb.Telemetry` |
| 7.13 | Single-user passwordless auth (MVP) | unauthenticated requests to anything except `/healthz`/`/readyz`/`/login` return 401; login is local-magic-link or hashed password |
| 7.14 | Rate limit on `/assignments` POST (per-IP via `Hammer`) | exceeds → 429 with `Retry-After` |

**Phase 7 exit criteria:** the umbrella runs end-to-end inside a Docker container, the tests pass against the released artifact, and the security gate for Phase 5 is unblocked.

---

## 11. Phase 8 — UAT Certification

**Goal:** independent verification that a non-technical user can complete every required scenario.

### 8.1 — Run the full umbrella test suite
- `cd builder && mix test` → 0 failures. Capture transcript at `evidence/phase8/mix_test.txt`.

### 8.2 — Run the full Playwright suite
- `cd builder/e2e && npx playwright test` → 0 failures. Capture HTML report at `evidence/phase8/playwright-report/`.

### 8.3 — Run the boot smoke per `release_checklist.md`
- Follow `builder/docs/run.md` exactly. Time it. It must take less than five minutes from a clean clone.

### 8.4 — Walk every scenario in `scenario_certification.md`
- For each row (SCN-01..SCN-10), execute the path manually through the UI. Check each row's "deterministic evidence", "user-visible outcome", and "no Elixir editing". Capture screenshots in `evidence/phase8/scenarios/SCN-XX/`.

### 8.5 — Re-audit traceability
- For every row in `verification.md` that is now `done`, link to (a) the test name, (b) the screenshot, (c) the commit. Anything still `deferred` must reference an explicit `GAP-MVP-XXX` row that is openly tracked, not silently dropped.

### 8.6 — Update the audit report
- Append `builder/docs/post_build_audit_2026-04-11.md` with a "Closing Audit" section that walks back through G-001..G-008 with current status. The verdict must move from **No-Ship** to **Ship** (or document precisely which gaps remain).

### 8.7 — Sign-off
- Fill in the sign-off template at the bottom of `builder/docs/release_checklist.md`. Decision: ship.

**Phase 8 exit criteria:** the release checklist is signed off and the audit report verdict is updated.

---

## 12. Definition of Done (the artifacts you must produce)

A work item is done when ALL of these exist and are committed:

- [ ] Test file exists, was RED first, is now GREEN.
- [ ] LiveView (if a UI item) renders real data and produces real side effects.
- [ ] Audit row gets emitted on every write.
- [ ] PubSub broadcast on every state-changing event.
- [ ] Screenshot under `builder/docs/evidence/phase<N>/<item>.png`.
- [ ] Playwright spec passing (if Tier A/B/C).
- [ ] `verification.md` row updated with status + confidence + commit hash.
- [ ] `capability_map.md` row updated.
- [ ] If the work item closes a `GAP-MVP-*` row, that row is removed from `next_steps.md`.

The umbrella is production-ready when ALL of:

- [ ] `cd builder && mix test` is green (every app, 0 failures).
- [ ] `cd builder && MIX_ENV=prod mix release jido_builder` succeeds.
- [ ] `docker build -f builder/Dockerfile -t jido-builder:rc .` succeeds.
- [ ] `docker run jido-builder:rc` serves `/healthz` 200 and the home page.
- [ ] `podman run` of the same image works (rootless).
- [ ] Every Tier A/B/C scenario passes via Playwright headless.
- [ ] `verification.md` has zero `deferred` rows for Tier A/B/C primitives.
- [ ] `next_steps.md` only contains genuinely deferred Tier D/E/extension items.
- [ ] `release_checklist.md` is signed off.
- [ ] The audit report's verdict has been updated to **Ship**.

---

## 13. Working Agreements

| # | Agreement |
|---|---|
| W1 | **One PR per work item.** PR title format: `<phase>.<item>: <imperative summary>` (e.g. `1.1: hire form actually hires`). |
| W2 | **PR description includes the seven DDTDD steps inline** (Discovery, RED, VERIFY, GREEN, REFACTOR, VALIDATE, DONE) with file paths and commit hashes. |
| W3 | **Branch name:** `phase<N>/<item-slug>` (e.g. `phase1/hire-form-actually-hires`). |
| W4 | **CI must pass before merge.** Add `mix test`, `mix format --check-formatted`, `mix credo --strict`, and a smoke `mix compile --warnings-as-errors` to `.github/workflows/ci.yml` (create it if missing). |
| W5 | **No silent feature creep.** If a work item discovers a second bug, file a new work item (just append it to this doc with a clear ID like `0.8`, `2.9`, etc.) — do not bundle. |
| W6 | **Screenshots are mandatory** for every UI work item. Stored under `builder/docs/evidence/phase<N>/`. Reviewed during PR. |
| W7 | **The plan is alive.** If reality forces a deviation, edit this file in the same PR that deviates and explain why in the PR description. |
| W8 | **Read upstream first.** No work item begins without the Discovery paragraph. PRs without it are rejected. |

---

## 14. Open Questions Codex Must Answer Before Phase 5

The BUILDER_PLAN §10 already lists open questions. Re-state them here so Codex flags them to the user **before** entering Phase 5 (codegen) — they affect security model and product surface:

1. **LLM provider for Phase 5 SCN-06 (`scenario_fake_llm_roundtrip`)**: which fake provider should the integration test use? (Recommend a deterministic stub registered in `Settings → Integrations` that just echoes the prompt.)
2. **Default storage adapter**: ETS (default) is fine for MVP but ask whether prod should ship with File or Redis as the recommended default.
3. **Codegen production mode**: in `MIX_ENV=prod`, hot-compile via `Code.compile_file/1` is unusual. Confirm whether the user wants it (faster iteration, slightly riskier) or a "write-then-restart" mode (safer, requires a controlled restart).
4. **Auth model**: Phase 7.13 lists single-user passwordless. Confirm before implementing.
5. **Multi-tenant isolation level**: BUILDER_PLAN allows partition-based tenancy via Jido `partition_key/2`. Confirm whether multiple workspaces in one BEAM are sufficient or whether real OS-level isolation is needed for prod.

---

**End of plan. Codex: start with Phase 0, work item 0.1. No skipping. No bundling. One DDTDD ritual per commit.**
