# JidoBuilder — Phase 1→8 Implementation Plan

## Context

JidoBuilder is a Phoenix LiveView no-code UI that exposes every Jido Elixir
agent capability to non-technical users. Phase 0 (stabilization) closed on
2026-04-12 at commit `c094e87` with 27 tests / 0 failures across the five
umbrella apps under `builder/`. The repo already has the full data layer
(18 Ecto tables, all schemas from `BUILDER_PLAN §2.3`), the runtime Jido
wrapper (`JidoBuilderRuntime.Jido`, `Hiring`, `Signals`, `DirectiveEmitter`,
`TelemetryBridge`, `EventBus`), the codegen pipeline (`CompileQueue`,
`FileWriter` with `Path.expand/1` sandbox, 5 EEx templates), and the web
shell (four real LiveViews: `DashboardLive`, `AgentLive`, `WorkflowBuilderLive`,
plus `HealthController` with `/healthz` + `/readyz`). Four LVs are stubs
(`RosterLive`, `SchedulesLive`, `TeamsLive`, `SettingsLive`). `config/runtime.exs`
and the multi-stage `Dockerfile` already landed in the 0.x batch (Phase
7.1/7.2/7.4/7.7 are effectively done).

This plan covers the remaining work from Phase 7 (items 7.3, 7.5, 7.6,
7.10–7.14), the Phase 1 single truth path, Phases 2–6 (Tier A–E feature
surfaces), and Phase 8 (UAT certification). The goal is moving the audit
verdict from *No-Ship* to *Ship* while honoring the DDTDD ritual
(Discovery → RED → VERIFY → GREEN → REFACTOR → VALIDATE → DONE) on every
work item. No production code lands before a failing test exists.

## Cross-Cutting Decisions (answered in plan mode)

| # | Decision | Rationale |
|---|---|---|
| D1 | **Auth = local bcrypt password** (7.13) | User-chosen. No SMTP dependency, zero external services. Single user, hashed password in `users` table, signed session cookie. |
| D2 | **Auth ships BEFORE Phase 1** | User-chosen. Every LiveView is built auth-aware from day one via `on_mount` hook in `live_session`; zero retrofit. |
| D3 | **Workflow DAG = D3 via LiveView hook** (Phase 2.x) | User-chosen. Drag-and-drop node editor via a `phx-hook="WorkflowDag"` that mounts a D3 canvas, with selections/edges pushed back to LV via `pushEvent`. |
| D4 | **Scheduler = Jido.Scheduler (upstream)** | User-chosen. Zero new deps; maps 1:1 to `Jido.Agent.Directive.Cron` / `CronCancel` from §0.3. |
| D5 | **Phase 1 truth path triggered from LiveView buttons**, not a Mix task | The DDTDD plan §4 work items 1.1–1.5 demand LV→context→runtime→Jido wiring. A Mix task would leave the UI unproven and defeat the audit's "demo-trust unlock" goal. |
| D6 | **Phase 5 (codegen editors) is gated by 7.5 + 7.6** | Security gate already documented; enforced by ordering. |

## Implementation Ordering (the dependency DAG)

```
  ┌──────────────────────────┐
  │ 7.3 Cloak key rotation   │ (isolated; security-ops)
  └────────────┬─────────────┘
               │
  ┌────────────▼─────────────┐
  │ 7.5 Path-allowlist fuzz  │  Phase 5 gate (can't ship codegen UI until these
  │ 7.6 EEx template fuzz    │  pass property fuzzing)
  └────────────┬─────────────┘
               │
  ┌────────────▼─────────────┐
  │ 7.13 Local bcrypt auth   │  D2: before Phase 1, ships auth-aware LVs
  └────────────┬─────────────┘
               │
  ┌────────────▼─────────────┐
  │ Phase 1 — single truth   │  Demo-trust unlock (roster hire → assign → stop)
  │ 7.14 rate-limit assignments (interleaved — the `/assignments POST` is born here)
  └────────────┬─────────────┘
               │
  ┌────────────▼─────────────┐
  │ Phase 2 — Tier A (10)    │  Vertical slice complete
  │ 7.11 structured logging  │  (interleave — ops hardening)
  │ 7.12 Prometheus /metrics │  (interleave — ops hardening)
  └────────────┬─────────────┘
               │
  ┌────────────▼─────────────┐
  │ Phase 3 — Tier B (7)     │  Teams / Workflows / Schedules / Sensors
  │ 7.10 SQLite WAL backup   │  (interleave)
  └────────────┬─────────────┘
               │
  ┌────────────▼─────────────┐
  │ Phase 4 — Tier C (6)     │  Operations + Trust
  └────────────┬─────────────┘
               │
  ┌────────────▼─────────────┐
  │ Phase 5 — Tier D (8)     │  Codegen block editors (unblocked by 7.5/7.6)
  └────────────┬─────────────┘
               │
  ┌────────────▼─────────────┐
  │ Phase 6 — Tier E (9)     │  Threads, Memory, Identity, Debug, A11y polish
  └────────────┬─────────────┘
               │
  ┌────────────▼─────────────┐
  │ Phase 8 — UAT + audit    │  Walk verification.md, update audit verdict → Ship
  └──────────────────────────┘
```

## Phase 7a — Security-Critical (Phase 5 Gate)

### 7.3 — Cloak Key Rotation Mix Task

- **Critical files**: `apps/jido_builder_core/lib/jido_builder_core/vault.ex`,
  `apps/jido_builder_core/lib/mix/tasks/jido_builder/rotate_cloak_key.ex` (new),
  `apps/jido_builder_core/lib/jido_builder_core/security.ex`.
- **Discovery**: read upstream Cloak.Ecto `Cloak.Ciphers.AES.GCM` docs and
  `Cloak.Ecto.Migrator` (the `.migrate/2` walker). Confirm the vault module
  already declares a single cipher — we'll add a `default:` vs `legacy: [...]`
  slot pattern.
- **RED**: new test `apps/jido_builder_core/test/vault_rotation_test.exs`:
  1. Insert a `secrets` row (encrypted with V1 key).
  2. Run `Mix.Task.run("jido_builder.rotate_cloak_key", [...])`.
  3. Assert the row's ciphertext bytes changed.
  4. Assert `get_secret_for_runtime/2` still decrypts to the original plaintext.
- **GREEN**: update `Vault` to declare `default: V2`, `legacy: [V1]`. Add a
  `Mix.Tasks.JidoBuilder.RotateCloakKey` that `Cloak.Ecto.Migrator.migrate/2`'s
  every table containing `:binary` cipher columns (start with `secrets`,
  `integrations`, extend as new columns appear).
- **VALIDATE**: full `mix test` green; manual rotation of a dev fixture.
- **Closes**: part of `GAP-MVP-017`.

### 7.5 — Path-Allowlist Property Fuzz (Phase 5 gate)

- **Critical files**: `apps/jido_builder_codegen/lib/jido_builder_codegen/file_writer.ex`
  (already does `Path.expand/1` + `String.starts_with?(expanded, root <> "/")`),
  `apps/jido_builder_codegen/test/file_writer_fuzz_test.exs` (new).
- **Discovery**: re-read the existing `resolve_path/1` (lines 20–32). Confirm
  behavior under (a) absolute paths `/etc/passwd`, (b) `..`-escaping
  relatives, (c) Windows drive-letter absolutes, (d) null-byte injection,
  (e) URL-encoded paths, (f) symlinks. The current check is sound for the
  first three but has never been fuzzed.
- **RED**: add StreamData-based property test that generates 1000+ adversarial
  paths (using a mix of `StreamData.binary`, `string(:printable)`, and
  hand-crafted edge cases) and asserts **every** one that resolves outside
  the configured root gets rejected with `{:error, :path_outside_generated_lib}`.
  A second property: every path that resolves inside the root is accepted
  and returns a canonical absolute path. Mark failing until shape is tight.
- **GREEN**: add StreamData dep to `apps/jido_builder_codegen/mix.exs`
  (test-only). If the fuzz finds real escapes, harden `resolve_path/1` by:
  (a) rejecting paths containing null bytes, (b) using `Path.safe_relative/1`
  where it exists, (c) resolving symlinks with `File.realpath/1` before
  comparison.
- **VALIDATE**: `mix test apps/jido_builder_codegen/test/file_writer_fuzz_test.exs`
  green for at least 1000 StreamData iterations; run on Linux + Windows.
- **Closes**: part of `GAP-MVP-010`; Phase 5 security gate (half of two).

### 7.6 — EEx Template Property Fuzz (Phase 5 gate)

- **Critical files**: `apps/jido_builder_codegen/lib/jido_builder_codegen/templates/{action,agent,plugin,sensor,strategy}.ex`,
  `apps/jido_builder_codegen/test/template_fuzz_test.exs` (new).
- **Discovery**: inspect each template module. Identify every user-controllable
  assign (name, description, module name, slug, schema, block source). For
  each, confirm it is rendered through `inspect/1` or a strict whitelist.
  Item 0.9 already hardened `@moduledoc` via `inspect/1`; the rest of the
  templates need the same guarantee.
- **RED**: StreamData property test that generates adversarial strings
  (shell metachars, `#{System.cmd(...)}`-style Elixir interpolation,
  triple-quoted heredocs, zero-width chars, Unicode right-to-left override)
  and asserts (a) the rendered source parses with `Code.string_to_quoted/1`,
  (b) the AST contains no calls to dangerous modules (`System`, `File`,
  `Code`, `:os`, `Port`), (c) compiling the rendered module produces the
  expected module name — the attacker's payload becomes a string literal,
  not executable code.
- **GREEN**: for any template that currently uses raw interpolation, wrap
  user assigns in `inspect/1` or `Macro.escape/1`. Add a `Templates.safe/1`
  helper if patterns repeat.
- **VALIDATE**: 1000+ iterations green. `mix test apps/jido_builder_codegen/test/template_fuzz_test.exs`.
- **Closes**: part of `GAP-MVP-010`; Phase 5 security gate (other half).

## Phase 7b — Auth (shipping before Phase 1 per D2)

### 7.13 — Local Bcrypt Single-User Auth — **DONE**

> **Note (2026-04-11):** Shipped with `pbkdf2_elixir` (pure-Elixir Comeonin
> adapter) instead of `bcrypt_elixir`. The Windows dev environment has no
> C toolchain, and `bcrypt_elixir` requires `make`/`cc` to build its NIF.
> `pbkdf2_elixir` offers the same `hash_pwd_salt` / `verify_pass` /
> `no_user_verify` API, is also Comeonin-backed, and has an equivalent
> threat model for local single-user auth. The migration table, context
> module, session controller, LV, and routing wiring are otherwise
> identical to the plan. No `--force` / dev-default-admin flow shipped in
> this PR — the Mix task is strict (no self-signup), and the prod
> boot-refusal check is deferred to the GAP-MVP-017 settings work later.

- **Critical files**:
  - `apps/jido_builder_core/lib/jido_builder_core/accounts.ex` (new context)
  - `apps/jido_builder_core/lib/jido_builder_core/accounts/user.ex` (new schema)
  - `apps/jido_builder_core/priv/repo/migrations/YYYYMMDD_create_users.exs` (new)
  - `apps/jido_builder_web/lib/jido_builder_web/controllers/session_controller.ex` (new)
  - `apps/jido_builder_web/lib/jido_builder_web/live/login_live.ex` (new)
  - `apps/jido_builder_web/lib/jido_builder_web/user_auth.ex` (new; `on_mount` hook + plug)
  - `apps/jido_builder_web/lib/jido_builder_web/router.ex` (wrap `live_session`)
  - `apps/jido_builder_web/lib/mix/tasks/jido_builder/create_user.ex` (new; bootstrap the single user via Mix task — no self-signup)
- **Discovery**: read Phoenix auth generator template (`mix phx.gen.auth`) —
  we use it as a reference but hand-write a minimal subset (no registration,
  no reset, no confirmation, no email). Dependencies added: `{:bcrypt_elixir, "~> 3.0"}`.
- **RED**: tests under `apps/jido_builder_web/test/jido_builder_web/user_auth_test.exs`:
  1. Unauthenticated GET to `/` redirects to `/login` with 302.
  2. GET to `/healthz` and `/readyz` remain 200 (excluded from auth).
  3. POST to `/login` with correct credentials sets session cookie and
     redirects to `/`.
  4. POST with wrong password returns 401 and no session.
  5. `on_mount` hook assigns `:current_user` to LiveView socket.
- **GREEN**: implement the modules. Single user only — the `create_user` Mix
  task exits non-zero if a user already exists (unless `--force` is passed).
  Wrap all feature routes in `live_session :authenticated, on_mount: {UserAuth, :require_authenticated}`.
  Exclude `/healthz`, `/readyz`, `/login`, assets from auth via plug
  pipeline ordering. Ship a dev-mode default user (`admin` / `admin`)
  **only** when `Mix.env() != :prod`; prod refuses to boot without a user.
- **VALIDATE**: full suite green (~35 tests expected), manual browser flow,
  screenshot at `builder/docs/evidence/phase7/7_13_login.png`.
- **Closes**: `GAP-MVP-017` auth row.

## Phase 1 — Single Truth Path (demo unlock)

Follows DDTDD execution plan §4 verbatim. Each work item is one PR, one
DDTDD ritual. Target: the audit's #1 demo-trust risk closed.

### 1.1 — Roster Hire Form Actually Hires (`GAP-MVP-001`)

- **Critical files**:
  - `apps/jido_builder_web/lib/jido_builder_web/live/roster_live.ex` (currently
    a 15-line stub at `roster_live.ex:1–15`)
  - `apps/jido_builder_core/lib/jido_builder_core/roster.ex` (new context —
    thin wrapper that delegates `hire/2` → `JidoBuilderRuntime.Hiring.start/3`
    and `list/1` → `Hiring.list/1`)
  - `apps/jido_builder_web/test/jido_builder_web/live/roster_hire_test.exs` (new)
- **Reuse**: `JidoBuilderRuntime.Hiring.start/3` (`hiring.ex:12`) already
  validates context + delegates to `Jido.start_agent/3` + writes directive
  log. Don't reimplement — the LV just needs to build `%{workspace_id, actor}`
  from `socket.assigns.current_user` (from 7.13) and call it.
- **RED**: see DDTDD §4 item 1.1 — `render_submit/2` on the hire form asserts
  (a) `Jido.list_agents(JidoBuilderRuntime.Jido, partition: ...)` contains
  the new id, (b) `agent_instances` row exists with status `:running`,
  (c) `audit_events` has a `roster.hire` row, (d) the LV re-renders with
  the new row visible.
- **GREEN**: replace the stub with (1) a template picker (`TemplateListLive`
  query), (2) a display name input, (3) a partition select, (4) a "Hire"
  button that pushes `handle_event("hire", params, socket)`, (5) a roster
  table fed by `Roster.list/1`, subscribed to
  `EventBus.workspace_activity_topic(workspace_id)` for live updates.
- **VALIDATE**: first Playwright spec — `e2e/tests/hire_truth_path.spec.ts`.
  Screenshot `evidence/phase1/01_hire.png`.
- **DONE**: mark `Start agent`, `List running agents`, `Count agents`,
  `Whereis by ID` rows in `verification.md` as `done` confidence 5.

### 1.2 — Assignments Console Dispatches a Signal (`GAP-MVP-002`)

- **Critical files**:
  - `apps/jido_builder_web/lib/jido_builder_web/live/assignments/new_live.ex` (new)
  - `apps/jido_builder_web/lib/jido_builder_web/router.ex` (add route
    `live "/assignments/new", AssignmentsNewLive, :new`)
  - `apps/jido_builder_web/test/jido_builder_web/live/assignment_dispatch_test.exs` (new)
- **Reuse**: `JidoBuilderRuntime.Signals.new/call/cast` already exists
  (per inventory). Don't re-implement signal composition.
- **RED**: the test hires a test agent via `Roster.hire/2`, opens the new LV,
  picks the agent + signal type + JSON payload, submits, then asserts
  `signals_log` row inserted, PubSub broadcast on `"agent:<id>"`, and agent
  state visibly changed via `AgentServer.state/1`.
- **GREEN**: build the LV. Form fields: target agent (select from running
  agents via `Roster.list/1`), signal type (text), payload (textarea, parsed
  as JSON and validated server-side). On submit → `Signals.new` →
  `Signals.call` → result feedback panel. Feedback panel shows either the
  sync return value or a "dispatched async" confirmation.
- **Note (7.14 interlock)**: this is the exact endpoint 7.14 rate-limits.
  Wire Hammer (see 7.14 below) in the same PR or immediately after — do not
  leave the assign endpoint unprotected.
- **VALIDATE**: Playwright `e2e/tests/assignment_dispatch.spec.ts`. Screenshot.
- **DONE**: mark `Sync signal send`, `Async signal send`, `Build CloudEvent signal`
  rows done.

### 1.3 — Activity Stream With Plain-Language Rows (`GAP-MVP-007`)

- **Critical files**:
  - `apps/jido_builder_core/lib/jido_builder_core/observability.ex` (add
    `translate_event/1` pure function)
  - `apps/jido_builder_web/lib/jido_builder_web/live/dashboard_live.ex`
    (currently real; add translation layer when rendering stream rows)
  - `apps/jido_builder_web/test/jido_builder_web/live/dashboard_activity_test.exs` (new)
- **Reuse**: `TelemetryBridge` already bridges `[:jido, :agent, :cmd, ...]`
  to PubSub (per inventory). `DashboardLive` already subscribes to
  `EventBus.workspace_activity_topic/1` and streams events. The missing
  piece is *translation*: raw `agent.cmd.stop` → plain English.
- **RED**: the test fires a real `cmd/2` against an agent then asserts the
  `DashboardLive` stream contains `%{label: "Worker <name> completed task
  <X> in NNms", status: :success, agent_link: "/agents/<id>"}` — explicitly
  NOT the raw event name.
- **GREEN**: implement `Observability.translate_event/1` that takes a
  telemetry metadata map and returns `%{label, status, agent_link, ts,
  next_hint}`. On `:error`, populate `next_hint` with e.g. `"Open the
  worker's debug panel"`.
- **VALIDATE**: screenshot `evidence/phase1/03_activity.png`.
- **DONE**: mark `Live telemetry stream`, `Per-agent events stream` done.

### 1.4 — Stop Agent With Confirmation (`GAP-MVP-001`)

- **Critical files**: `roster_live.ex` (extended), new confirmation modal
  component in `core_components.ex` if not present.
- **Reuse**: `JidoBuilderRuntime.Hiring.stop/2` already exists
  (`hiring.ex:24`). LV just wraps it.
- **RED**: test that (a) clicking Stop without confirming is a no-op,
  (b) confirming removes the row, fires a `roster.stop` audit event, and
  broadcasts on the workspace topic.
- **GREEN**: add a `.confirm_modal` component with the exact copy
  `"Stop worker <name>? In-flight tasks (<count>) will be cancelled."`
  per BUILDER_PLAN §3.4. Wire `handle_event("stop", ...)` →
  `Hiring.stop/2` → broadcast.
- **VALIDATE**: Playwright covering both confirm-cancel and confirm-confirm.
- **DONE**: mark `Stop agent`, `Directive Stop` rows done.

### 1.5 — End-to-End Scenario Certification

- New Playwright spec `e2e/tests/scenario_truth_path.spec.ts` walks
  login → roster hire → assign signal → observe stream → stop with confirm.
  Video captured at `evidence/phase1/05_truth_path.webm`.
- Mark SCN-01 in `scenario_certification.md` as `pass`.

### 7.14 — Rate Limit on `/assignments` POST (shipped with Phase 1.2)

- **Critical files**: `apps/jido_builder_web/lib/jido_builder_web/router.ex`
  (add plug), `apps/jido_builder_web/lib/jido_builder_web/plugs/rate_limit.ex` (new).
- **Reuse**: Hammer (`{:hammer, "~> 6.1"}`). ETS backend, 10 req/min per IP,
  the LV `handle_event("dispatch", ...)` calls `Hammer.check_rate/3` before
  touching `Signals.call`.
- **RED**: test that the 11th dispatch within a minute returns an error
  assigns `:error` message "Too many signals. Try again in <N> seconds."
- **GREEN**: Hammer config in `config/config.exs`, plug attached to the
  assignments live session, error UI path.
- **VALIDATE**: integration test green.

## Phase 2 — Tier A (rest of vertical slice)

Per DDTDD §5 — ten surfaces. Per-item DDTDD ritual is identical to Phase 1.
Ordered by dependency:

| # | Surface | Primary files | Runtime call | Test name |
|---|---|---|---|---|
| 2.1 | App shell + Cmd+K palette | `components/app_shell.ex`, `live/command_palette_live.ex` | router+LV navigate | `app_shell_navigation.spec.ts` |
| 2.2 | Home KPIs | `live/dashboard_live.ex` (extend) | `Hiring.count/1` + telemetry rollups | `home_kpi_live_test.exs` |
| 2.3 | Templates Library | `live/templates/index_live.ex` | `Templates.list/1` (context exists) | `templates_index_test.exs` |
| 2.4 | Template Editor | `live/templates/edit_live.ex` | `Templates.upsert/2` | `template_editor_test.exs` |
| 2.5 | Agent Detail (extend) | `live/agent_live.ex` (currently real) | `AgentServer.state/1`, `recent_events/2` | `agent_detail_state_test.exs` |
| 2.6 | Skills catalog | `live/skills/{index,detail}_live.ex` | `Jido.Discovery.list_actions/1`, `get_action_by_slug/1` | `skills_catalog_test.exs` |
| 2.7 | Work Styles picker | `live/work_styles/index_live.ex` | Strategy enum on template | `work_styles_pick_test.exs` |
| 2.8 | Directives Builder (all 11) | `live/directives/builder_live.ex` | `DirectiveEmitter` (extend if needed) | `directives_builder_test.exs` (parameterized) |

**Interleave during Phase 2:**
- **7.11** Structured JSON logger — add `{:logger_json, "~> 5.0"}` or
  configure `Logger.Backends.Console` with a JSON formatter. Test: one
  JSON line per log entry in `MIX_ENV=prod`.
- **7.12** Prometheus `/metrics` — add `{:telemetry_metrics_prometheus_core, "~> 1.0"}`,
  mount on `/metrics` in the API scope (no auth — or behind basic auth
  depending on user preference). Test: `curl /metrics` returns the four
  `phoenix_*` summaries from `JidoBuilderWeb.Telemetry`.

**Phase 2 exit**: all 10 Tier A rows in `verification.md` move to `done`.

## Phase 3 — Tier B (team orchestration)

Per DDTDD §6. Seven surfaces:

| # | Surface | Closes |
|---|---|---|
| 3.1 | Capability Packs (plugin browser + edit) | `GAP-MVP-008` |
| 3.2 | Watchers (sensor browser + configurator) | `GAP-MVP-008` |
| 3.3 | Teams / Pods MVP | `GAP-MVP-012` |
| 3.4 | Hierarchy view | `GAP-MVP-009` |
| 3.5 | Playbooks / Workflow Builder (D3 DAG — per D3) | `GAP-MVP-002` |
| 3.6 | State Ops editor (all 5 ops) | `GAP-MVP-005` |
| 3.7 | Schedules (cron create / cancel via `Jido.Scheduler`) | `GAP-MVP-006` |

**Workflow Builder (3.5)** specifics (D3 decision):
- Critical files: `assets/js/hooks/workflow_dag.js` (new), `live/workflow_builder_live.ex`
  (currently real but scaffolded; extend).
- The LV holds workflow state (nodes + edges) as assigns. On mount, pushes
  the graph to the D3 hook via `pushEvent("init_graph", ...)`. Node
  drag/drop pushes `:node_moved` back. Edge create/delete pushes
  `:edge_upserted` / `:edge_removed`. Server persists to `workflow_steps`
  on save.
- Test: `workflow_dag_test.exs` asserts LV dispatches `:init_graph` on
  mount and persists node/edge events to DB.

**Scheduler (3.7)** specifics:
- Use `Jido.Scheduler` and `Jido.Scheduler.Job` from upstream. The LV
  creates `Directive.cron/2` directives through the existing
  `DirectiveEmitter`. Cancel via `Directive.cron_cancel/1`.

**Interleave**:
- **7.10** SQLite WAL-aware backup script at `infra/backup.sh` —
  issues `sqlite3 <db> ".backup <dest>"` which is WAL-safe. CI job restores
  into a scratch dir and reruns the test suite.

## Phase 4 — Tier C (operations + trust)

Per DDTDD §7. Six surfaces: Audit History, Vault (hibernate/thaw),
Traces viewer, Pools, Settings/Integrations/Secrets, Workspaces (partition
CRUD). Nothing architecturally novel — each is a CRUD LV over existing
contexts + one Jido primitive. Expected test count uplift: ~25 tests.

## Phase 5 — Tier D (codegen block editors) — GATED

**Unblocked only after 7.5 + 7.6 pass.**

Per DDTDD §8. Eight surfaces: block library + validator, compile pipeline
hardening (rollback + sandbox + discovery refresh — already done in
`compile_queue.ex`), Action editor, Sensor editor, Plugin editor, Strategy
editor, FSM Designer, Ejector (export-as-Elixir).

**Key reuse**: the `CompileQueue.enqueue/2` pipeline at
`compile_queue.ex:20–41` already handles validate→write→compile→refresh→
audit→rollback. Phase 5 adds a block library (JSON tree → block struct),
a UI that edits the tree, and the Ejector that renders the tree as a
standalone Elixir module without compiling.

## Phase 6 — Tier E (polish)

Per DDTDD §9. Nine items: Threads explorer, Memory spaces, Identity profiles,
Glossary, Onboarding walkthrough, Debug panel (live ring buffer via
`AgentServer.recent_events/2`), Error Policy editor, Orphans & Adoption
view, accessibility audit (axe-core in Playwright).

**Dark-mode toggle** is part of the polish: add a `user.theme` column to
the `users` schema (7.13) and a `phx-click` toggle in the app shell that
writes to session + user profile.

## Phase 8 — UAT Certification

Per DDTDD §11:
1. `cd builder && mix test` → 0 failures; transcript at `evidence/phase8/mix_test.txt`.
2. `cd builder/e2e && npx playwright test` → 0 failures; HTML report at
   `evidence/phase8/playwright-report/`.
3. Boot smoke per `builder/docs/run.md`; time under 5 min from clean clone.
4. Walk every SCN-01..SCN-10 manually; screenshots at
   `evidence/phase8/scenarios/SCN-XX/`.
5. For every `done` row in `verification.md`, link to (test, screenshot, commit).
6. Append "Closing Audit" section to `builder/docs/post_build_audit_2026-04-11.md`
   walking back through G-001..G-008, updating verdict from **No-Ship** → **Ship**.
7. Sign off `builder/docs/release_checklist.md`.

## Risks & Open Items Not Already in the Prompt

| # | Risk | Mitigation |
|---|---|---|
| R1 | Phase 2.3 Templates Library depends on a `Templates` context that already has full CRUD — but the DDTDD plan assumes more schema fields (`schema_fields`, `plugin_slugs`, `allowed_action_slugs`) than the current migration exposes. May need a migration during Phase 2. | Audit `templates/template.ex` at start of Phase 2.3; file a new work item 2.3.0 for migration if gaps exist. |
| R2 | Phase 3.5 Workflow Builder with D3 introduces the first non-trivial JS surface. `assets/js/hooks/` may not exist yet. | Scaffold `assets/js/app.js` hook registration during 2.1 App Shell work so Phase 3.5 has a landing pad. |
| R3 | Phase 5.7 FSM Designer is listed in DDTDD but FSM state machines are a deep rabbit hole. The DDTDD plan doesn't specify complexity. | Time-box 5.7 to a states+transitions table editor in Phase 5; defer visual FSM diagram rendering to Phase 6 polish if time pressure. |
| R4 | `JidoBuilderRuntime.Signals` API shape not directly read in plan mode; may need adjustment. | First step of Phase 1.2 Discovery = read `signals.ex` end-to-end; file surface-match work item if API diverges from assumption. |
| R5 | 7.12 Prometheus `/metrics` endpoint: should it be behind auth or open for scraping? | Default to auth-off (scrapers need unauthenticated access), bind to localhost by default with `METRICS_BIND=127.0.0.1`. Flag for user. |
| R6 | 7.13 dev-mode default user `admin/admin` is a security smell if it leaks to prod. | Mix task refuses to seed the default user if `Mix.env() == :prod`; prod `config/runtime.exs` raises on boot if `users` table is empty. |
| R7 | The plan re-uses `EventBus.workspace_activity_topic/1` from inventory but the exact function signature wasn't verified in plan mode. | First step of every Phase 1 LV work item: `grep workspace_activity_topic apps/jido_builder_runtime/lib/jido_builder_runtime/event_bus.ex` to confirm arity before wiring. |

## Verification (how we prove each phase is done)

**Per work item (every phase)**:
1. `cd builder && export PATH="$HOME/scoop/shims:$HOME/scoop/apps/elixir/current/bin:$PATH" && MIX_ENV=test mix test` → green. Test count visible in commit message.
2. Screenshot at `builder/docs/evidence/phase<N>/<item>.png` (mandatory for UI items).
3. Playwright spec at `builder/e2e/tests/<name>.spec.ts` green (Tier A/B/C items).
4. `builder/docs/verification.md` row updated with status + confidence + commit hash.
5. `builder/docs/capability_map.md` row updated.
6. If closes a `GAP-MVP-*`, remove from `builder/docs/next_steps.md`.

**Per phase exit**:
- Phase 7a (7.3, 7.5, 7.6) — codegen sandbox threat model signed off;
  Phase 5 gate unblocked.
- Phase 7b (7.13) — every feature route redirects unauth to `/login`.
- Phase 1 — `e2e/tests/scenario_truth_path.spec.ts` green end to end;
  SCN-01 marked `pass`.
- Phase 2 — all Tier A rows in verification.md `done`; interleaved 7.11/7.12
  ops items verified via `curl /metrics` and JSON log sample.
- Phase 3 — SCN-09 (cron) and SCN-10 (pod broadcast) pass.
- Phase 4 — SCN-07 (hibernate/thaw + partition move) passes.
- Phase 5 — SCN-05 (custom action visible in Skills) passes.
- Phase 6 — every nav item in BUILDER_PLAN §3.1 has a working screen;
  SCN-06 and SCN-08 pass; axe-core audit 0 violations.
- Phase 8 — release checklist signed off; audit report verdict = Ship.

**Baseline verification before starting implementation** (runs during
first work item of Phase 7a):
```
cd builder
export PATH="$HOME/scoop/shims:$HOME/scoop/apps/elixir/current/bin:$PATH"
MIX_ENV=test mix test
```
Expected: 27 tests, 0 failures. If different, diagnose before proceeding.

**Umbrella production readiness checklist** (gate for calling the job
done):
- [ ] `cd builder && mix test` green across every app.
- [ ] `cd builder && MIX_ENV=prod mix release jido_builder` succeeds.
- [ ] `docker build -f builder/Dockerfile -t jido-builder:rc .` succeeds.
- [ ] `docker run` serves `/healthz` 200 and the home page.
- [ ] `podman run` of the same image works (rootless).
- [ ] Every Tier A/B/C scenario passes via Playwright headless.
- [ ] `verification.md` has zero `deferred` rows for Tier A/B/C primitives.
- [ ] `release_checklist.md` signed off.
- [ ] Audit report verdict updated to **Ship**.

---

## Post-Approval Actions (first moves after ExitPlanMode)

On approval, I will execute these **in order** before touching any code:

1. **Copy this plan** to `builder/docs/phase_1_to_8_plan.md` so it lives
   alongside `ddtdd_execution_plan.md`, `verification.md`, and
   `capability_map.md`. The `.claude/plans/tidy-toasting-blossom.md` copy
   stays as the durable session artifact; the `builder/docs/` copy is the
   canonical repo reference.
2. **Save the new-chat kick-off prompt** (see below) to
   `builder/docs/phase_1_to_8_kickoff_prompt.md` for easy reuse.
3. **Run the baseline verification** exactly as the original handoff
   prompt specified:
   ```
   cd builder
   export PATH="$HOME/scoop/shims:$HOME/scoop/apps/elixir/current/bin:$PATH"
   MIX_ENV=test mix test
   ```
   Expected 27/0. If different, stop and diagnose before starting 7.3.
4. **Begin Phase 7a, work item 7.3** (Cloak key rotation Mix task) using
   the DDTDD ritual — Discovery → RED first.

## Kick-Off Prompt for New Chat

Paste the following into a fresh Claude Code session to resume work on
the approved plan. It assumes `git pull` has brought the repo to the
current main HEAD and that the approved plan lives at
`builder/docs/phase_1_to_8_plan.md`.

```text
You are taking over JidoBuilder — a no-code Phoenix LiveView UI for the
Jido Elixir agent framework. Phase 0 (stabilization) is closed at
27 tests / 0 failures on branch `main` (commit c094e87 or newer).

The approved phased implementation plan is at:
  builder/docs/phase_1_to_8_plan.md

Required reading before you write any code:
  1. builder/docs/phase_1_to_8_plan.md   (the approved plan you execute)
  2. BUILDER_PLAN.md                     (product vision + UI map)
  3. builder/docs/ddtdd_execution_plan.md (DDTDD methodology, phase detail)
  4. builder/docs/verification.md         (capability checklist)
  5. builder/docs/capability_map.md       (Jido → UI mapping)

Baseline verification (run before starting any work item):
  cd builder
  export PATH="$HOME/scoop/shims:$HOME/scoop/apps/elixir/current/bin:$PATH"
  MIX_ENV=test mix test

Expected: 27 tests, 0 failures. If different, diagnose before proceeding.

Methodology: DDTDD ritual is mandatory for every work item.
  Discovery → RED (failing test first) → VERIFY RED → GREEN (minimal
  production code) → REFACTOR → VALIDATE (full mix test) → DONE
  (verification.md + capability_map.md updated).

Never write production code before a failing test exists.
Never mark a task done without running the full suite.

Cross-cutting decisions already approved (do not re-litigate):
  D1: Auth = local bcrypt password (7.13).
  D2: Auth ships BEFORE Phase 1 so every LV is auth-aware.
  D3: Workflow Builder DAG = D3 via phx-hook.
  D4: Scheduler = upstream Jido.Scheduler / Scheduler.Job.
  D5: Phase 1 truth path is LV-button-driven (no Mix task).
  D6: Phase 5 (codegen editors) is gated by 7.5 + 7.6.

Start here:
  Phase 7a → work item 7.3 (Cloak key rotation Mix task).
  Read the critical files in section "Phase 7a — Security-Critical".
  Enter plan mode for 7.3 only if you discover the approach needs
  adjustment; otherwise execute the DDTDD ritual directly.

Ordering to follow (see plan DAG):
  7.3 → 7.5 → 7.6 → 7.13 → Phase 1 (with 7.14 interlocked in 1.2) →
  Phase 2 (interleaved 7.11 + 7.12) → Phase 3 (interleaved 7.10) →
  Phase 4 → Phase 5 → Phase 6 → Phase 8 (UAT + audit update).

Known noise to ignore unless the user flags it:
  - "return_diagnostics: true" warning from Elixir 1.19 Compiler.
  - "use Phoenix.ConnTest is deprecated" warning in three test files.
  - Compilation error printout in the rollback test is intentional
    (the test still passes).

Architecture facts you must not forget:
  - JidoBuilderRuntime.Jido uses otp_app: :jido_builder_runtime.
  - Use Jido.Agent returns %Jido.Agent{state: %{...}}, not %MyModule{}.
  - Signals (CloudEvents) route via Jido.Router.
  - After hot compile, always call Jido.Discovery.refresh/0.
  - Windows path checks: always Path.expand/1 before String.starts_with?.
  - Cloak JSON round-trip loses atom keys → always use string keys in
    test assertions that read redacted data.
  - Database: SQLite3 via ecto_sqlite3; Ecto.Adapters.SQL.Sandbox in test.

Per-work-item deliverables:
  - Failing test first, then production code, then full `mix test` green.
  - Screenshot at builder/docs/evidence/phase<N>/<item>.png for UI items.
  - verification.md row updated.
  - capability_map.md row updated.
  - GAP-MVP-* row closed in next_steps.md if the gap is fully resolved.
  - Conventional commits: feat(scope): / fix(scope): / test(scope): etc.
    Scope is one of core, runtime, codegen, web, infra, docs.

One PR per work item. No sweeping refactors. No bundling.

Your first action in the new chat: read the plan file end-to-end, then
start DDTDD Discovery on work item 7.3.
```
