# Phase 1→8 Kick-Off Prompt

Paste the block below into a fresh Claude Code session (opened at the
`C:\Users\mpolz\Documents\JidoBuilder` repo root) to resume work on the
approved Phase 1→8 plan. The full plan lives at
`builder/docs/phase_1_to_8_plan.md`.

---

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

---

## Quick summary of what lands where

| Artifact | Location | Purpose |
|---|---|---|
| Approved plan (canonical) | `builder/docs/phase_1_to_8_plan.md` | In-repo, versioned, reviewed in PRs |
| Approved plan (session) | `C:\Users\mpolz\.claude\plans\tidy-toasting-blossom.md` | Durable local Claude plan artifact |
| Kick-off prompt | `builder/docs/phase_1_to_8_kickoff_prompt.md` | Paste into new chat to resume |
| DDTDD methodology | `builder/docs/ddtdd_execution_plan.md` | Work-item detail for every phase |
| Capability checklist | `builder/docs/verification.md` | Row-by-row done/deferred tracking |
| Jido → UI mapping | `builder/docs/capability_map.md` | Parallel capability table |
| Product vision | `BUILDER_PLAN.md` | Source of truth for scope |

## Cross-cutting decisions locked in (from plan mode)

- **D1** Auth = local bcrypt password (no SMTP, no passkey).
- **D2** Auth ships **before** Phase 1 so every LiveView is auth-aware.
- **D3** Workflow Builder DAG = **D3** via `phx-hook` (not Mermaid, not LV-native SVG).
- **D4** Scheduler = upstream `Jido.Scheduler` / `Jido.Scheduler.Job` (no Oban, no Quantum).
- **D5** Phase 1 truth path = LiveView buttons, not a Mix task.
- **D6** Phase 5 codegen editors are hard-gated by 7.5 + 7.6 passing property fuzz.
