# 1. Executive Verdict

**Overall verdict: No-Ship**

The delivered Builder implementation does **not** satisfy the source-of-truth plan or the stakeholder-operability standard. The plan requires a complete no-code manager-facing system that exposes Jido capability breadth and visibly executes real runtime behavior in UI; current implementation exposes only a small shell of pages and stream viewers. The current web layer has only seven routes and mostly static copy; critical business actions (hire, assign, organize, observe, recover, govern) are not executable from the UI. Runtime wrappers exist for hiring, signal dispatch, persistence, debug, directives, and discovery, but those modules are not wired into LiveView surfaces, so stakeholder-visible operation is not proven. Internal docs explicitly mark most capabilities as deferred, including core lifecycle, dispatch, observability controls, pods, codegen, and no-code workflows. Existing tests and Playwright checks primarily validate page rendering and text visibility, not end-to-end operator outcomes. Scenario-certification docs claim non-technical completion for advanced scenarios, but referenced flows are not present as routes or working controls, creating a trust risk. I could not run `mix test`/`mix phx.routes` in this environment because Hex dependencies could not be fetched (HTTP 403 through tunnel), so runtime verification is limited to static-code audit.

## Confidence rubric

- **Tier A — Runtime-verified:** claim confirmed by executed runtime checks (tests/server/routes) in this audit environment.
- **Tier B — Static-code verified:** claim confirmed directly from source/docs inspection, but not executed in this environment.
- **Tier C — Inferred:** claim is reasoned from available evidence but not directly verified in code execution.

Use this rubric for all confidence statements below; because runtime commands were blocked by dependency fetch failures, confidence is intentionally biased toward **Tier B (static-audit confidence)** unless explicitly stated otherwise.



**Evidence anchors**
- Claim: Verdict is **No-Ship** due to missing operator-critical UI execution paths.  
  Paths: `BUILDER_PLAN.md`; `builder/apps/jido_builder_web/lib/jido_builder_web/router.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/roster_live.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/workflow_builder_live.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/teams_live.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/schedules_live.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/settings_live.ex`  
  Identifiers: `JidoBuilderWeb.Router`, `live("/roster", ...)`, `live("/workflows", ...)`, `JidoBuilderWeb.RosterLive.render/1`, `JidoBuilderWeb.WorkflowBuilderLive.render/1`, `JidoBuilderWeb.TeamsLive.render/1`, `JidoBuilderWeb.SchedulesLive.render/1`, `JidoBuilderWeb.SettingsLive.render/1`  
  Distinctive string: `Build and hire agents into pods.`
- Claim: Runtime wrappers exist but are not visibly wired through web UI handlers.  
  Paths: `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/hiring.ex`; `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/signals.ex`; `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/persistence.ex`; `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/debug.ex`; `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/directive_emitter.ex`; `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/discovery.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/`  
  Identifiers: `JidoBuilderRuntime.Hiring`, `JidoBuilderRuntime.Signals`, `JidoBuilderRuntime.Persistence`, `JidoBuilderRuntime.Debug`, `JidoBuilderRuntime.DirectiveEmitter`, `JidoBuilderRuntime.Discovery`  
  Distinctive string: `defmodule JidoBuilderRuntime.Hiring do`
- Claim: Internal docs already mark broad capability surface as deferred.  
  Paths: `builder/docs/verification.md`; `builder/docs/capability_map.md`  
  Identifiers: verification table `Status` column; capability map rows for lifecycle/dispatch/observe/directives/state ops  
  Distinctive string: `| Start agent | Roster → Hire wizard | A | Jido.start_agent/3 | deferred |`
- Claim: Scenario certification and test focus are not equivalent to operational stakeholder outcomes.  
  Paths: `builder/docs/scenario_certification.md`; `builder/apps/jido_builder_web/test/`; `builder/e2e/tests/`  
  Identifiers: scenario status tables; LiveView assertions; Playwright expectations  
  Distinctive string: `toHaveText` / `rendered =~`

**Top 5 decisive facts**
1. Plan mandates complete no-code exposure of all Jido capabilities and real execution visibility; delivered surfaces are only a narrow subset.  
2. Router exposes only Home, Roster, Agent detail, Workflows, Schedules, Teams, Settings; all other required surfaces are absent.  
3. Roster/Schedules/Teams/Settings are placeholder pages with no operational controls.  
4. Capability map and verification docs mark nearly all core capabilities as `deferred`, including start/stop/list/count, directives, state ops, discovery, and monitoring controls.  
5. Runtime integration modules exist but have no references from web layer, indicating present-but-unwired backend capability.

**Confidence:** 4/5 (**Tier B — Static-code verified**). Rationale: verdict is strongly supported by direct source/doc inspection, but no runtime execution was completed in this environment.

**Evidence anchors**
- Fact 1 (plan demands broad no-code + real execution visibility):  
  Paths: `BUILDER_PLAN.md`; `builder/docs/verification.md`  
  Identifiers: mission/scope requirements; verification `Status` and `Blocker/Gap ID` columns  
  Distinctive string: `no-code`
- Fact 2 (router only exposes seven surfaces):  
  Paths: `builder/apps/jido_builder_web/lib/jido_builder_web/router.ex`  
  Identifiers: `JidoBuilderWeb.Router`, `live_session :default`, seven `live/3` declarations  
  Distinctive string: `live("/settings", SettingsLive, :index)`
- Fact 3 (Roster/Schedules/Teams/Settings are placeholders):  
  Paths: `builder/apps/jido_builder_web/lib/jido_builder_web/live/roster_live.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/schedules_live.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/teams_live.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/settings_live.ex`  
  Identifiers: `render/1` in each LiveView  
  Distinctive strings: `Build and hire agents into pods.` / `Manage recurring runs and temporal triggers.` / `Coordinate pods of specialized agents.` / `Project and runtime settings.`
- Fact 4 (core capability coverage marked deferred):  
  Paths: `builder/docs/verification.md`; `builder/docs/capability_map.md`  
  Identifiers: `Jido.start_agent/3`, `Jido.AgentServer.cast/2`, `Jido.Agent.Directive.*`, `Jido.Agent.StateOp.*`, `Jido.Observe*` rows  
  Distinctive string: `| deferred |`
- Fact 5 (runtime modules present but web references absent):  
  Paths: `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/`  
  Identifiers: `JidoBuilderRuntime.Hiring`, `JidoBuilderRuntime.Dispatch`, `JidoBuilderRuntime.Persistence`, `JidoBuilderRuntime.Debug`  
  Distinctive string: `defmodule JidoBuilderRuntime.`


---

# 2. Stakeholder Expectation Verdict

**Verdict: Fails Stakeholder Standard**

**Evidence**
- Stakeholder expectation of “living recruit pool” fails: Roster page is static text only; no hire form, table, actions, or status controls.  
- Manager-friendly operational control fails: navigation and routes omit most management surfaces (activity, traces, audit, integrations, assignments, hierarchy, pools, vault, etc.).  
- Visible/monitorable execution is partial: event streams exist, but they only render event name/status and do not provide layman-readable task progression, ownership, step state, outcomes, or remediation actions.  
- Workflow composition fails: Workflow page shows stream text but no composer/editor controls despite promise of graph composition.

**Major disappointments (stakeholder lens)**
- “Hire wizard” naming without hire interaction.
- “Workflow Builder” naming without building.
- “Teams (Pods)” naming without pod definition/edit/broadcast.
- “Settings” naming without runtime governance panels expected by plan.
- No layman-safe action-result loop (action -> run -> visible explanation -> next step).

**Stakeholder risk level: Critical** (demo trust loss likely within minutes).

**Confidence:** 4/5 (**Tier B — Static-code verified**). Rationale: UI surfaces and missing controls are directly visible in source/docs, but not runtime-tested in this environment.

---

# 3. Plan Conformance Verdict

**Verdict: Fails Plan Standard**

- **Architecture fidelity:** Partial pass. Umbrella structure and app boundaries exist and align with plan.  
- **Capability fidelity:** Fail. Plan requires broad Jido surface parity; internal verification states most capabilities are deferred.  
- **UI fidelity:** Fail. Plan targets a full manager control center; shipped UI is minimal route shell.  
- **Runtime fidelity:** Partial. Backend wrappers for many Jido primitives exist, but end-user execution path is not wired through UI.  
- **Testing/verification fidelity:** Fail for acceptance reality. Existing tests primarily confirm render/text and synthetic PubSub insertion; they do not prove layman operational workflows.

**Confidence:** 4/5 (**Tier B — Static-code verified**). Rationale: conformance gaps are explicit in plan/docs/router evidence, while runtime validation was not executed in this environment.

---

# 4. Layman UX / Ease-of-Use Verdict

**Verdict: Fails layman usability standard**

- Navigation is simple but incomplete; most expected managerial surfaces are absent.
- Language is plain, but functionality behind labels is missing on key pages.
- Discoverability is poor for real work because primary controls do not exist.
- Onboarding suitability is weak: docs “smoke test” is to verify headings/labels, not accomplish work.
- A basic business user cannot complete core goals (hire, assign, monitor completion, organize hierarchy, recover from failure) unaided.

**Confidence:** 4/5 (**Tier B — Static-code verified**). Rationale: UX conclusions come from direct UI source review; runtime walk-through with live server could not be executed.

---

# 5. Visible Execution & Monitoring Verdict

**Verdict: Partially wired, not operator-grade**

- Positive: Dashboard, Agent, and Workflow pages subscribe to PubSub topics and stream events.
- Gap: Display is low-fidelity (`event_name` + `status`) with no causal chain, no per-step workflow interpretation, no actionable insight for laymen.
- Gap: No dedicated Activity/Trace/Audit operational screens in router/nav.
- Gap: No proven user-triggered execution chain from UI control to runtime event generation.

**Confidence:** 3/5 (**Tier B — Static-code verified**). Rationale: stream/runtime wiring is visible in code, but end-to-end operator-triggered execution was not runtime-verified.

---

# 6. No-Code Reality Verdict

**Verdict: No-code claim not met**

- Runtime code supports lifecycle/dispatch/persistence wrappers, but UI lacks controls to invoke them.
- Scenario certification claims advanced no-code scenarios, but corresponding UI paths/surfaces are not implemented.
- Codegen app exists, but no surfaced block editor in current web routes.
- For current implementation, non-developer users cannot perform intended workflows without developer intervention.

**Confidence:** 4/5 (**Tier B — Static-code verified**). Rationale: no-code gaps are explicit in route/surface coverage and docs, while runtime usability was not exercised interactively.

---

# 7. Truthfulness of UI Verdict

**Verdict: Material truthfulness risk**

**Misleading / cosmetic patterns found**
- **“Roster / Hire Wizard”** page implies hiring controls but contains only explanatory text.
- **“Workflow Builder”** implies composition capability, but page only renders activity stream.
- **“Teams (Pods)”** implies pod management, but no create/edit/assign actions.
- **“Schedules”** implies temporal control; no cron creation/cancel controls.
- **Scenario certification** asserts objective execution coverage for advanced scenarios not represented in the route/UI/test implementation shown.

**Confidence:** 4/5 (**Tier B — Static-code verified**). Rationale: misleading labels are directly observable in page implementations and headings, but user-facing runtime demos were not executed.

---

# 8. Evidence Summary

Evidence sources used:
- **Specification baseline:** `BUILDER_PLAN.md` mission/scope requirements.
- **UI implementation:** router, layout nav, all LiveViews.
- **Runtime implementation:** telemetry bridge, hiring wrappers, runtime utility modules.
- **Quality docs:** capability map, verification matrix, scenario certification, run guide, next steps.
- **Tests:** LiveView tests, runtime integration test, Playwright e2e spec.
- **Execution attempt:** `mix test`, `mix phx.routes`, `mix local.hex --force`, `mix archive.install github hexpm/hex branch latest --force` (all blocked by dependency fetch 403).

Not verified due environment limitation:
- Live running server behavior against real dependencies.
- End-to-end runtime execution from browser actions (controls missing in code regardless).

**Confidence:** 5/5 (**Tier B — Static-code verified**). Rationale: this section is a direct inventory of inspected sources and explicitly documents blocked runtime checks.

---

# 9. Capability Audit Matrix

| Capability / Surface | Planned? | Present in Code? | Running in UI? | Real Execution Proven? | Layman Usable? | Stakeholder Expectation Met? | Status | Evidence | Severity if deficient |
|---|---|---|---|---|---|---|---|---|---|
| Home | Yes | Yes | Yes | Partial | Partial | No | Partially working | Stream list only | High |
| Workspaces | Yes | Partial (schema) | No | No | No | No | Missing UI | DB only | High |
| Roster | Yes | Minimal | Yes | No | No | No | Present but unwired | Static text page | Critical |
| Hire flow | Yes | Runtime wrapper exists | No | Runtime test only | No | No | Present-but-unwired | No UI action path | Critical |
| Templates | Yes | Core schema/context | No | No | No | No | Missing in UI | No route | High |
| Skills | Yes | Discovery wrapper | No | No | No | No | Missing | No route | High |
| Capability Packs / Plugins | Yes | Dynamic plugin resolver | No | No | No | No | Missing | No route | High |
| Watchers / Sensors | Yes | Dynamic sensor + host | No | No | No | No | Missing | No route | High |
| Work Styles / Strategies | Yes | Codegen template exists | No | No | No | No | Missing | No route | Medium |
| Teams / Pods | Yes | Pod config runtime | Minimal page only | No | No | No | Partially wired | No controls | High |
| Playbooks / Workflows | Yes | Workflow schema/context | Minimal page | No | No | No | Partially wired | No builder UI | Critical |
| Assignments | Yes | Signals/dispatch modules | No | No | No | No | Missing | No route | Critical |
| Directives | Yes | Directive emitter module | No | Not proven | No | No | Present-but-unwired | No UI | High |
| State Ops | Yes | StateOp action module | No | Not proven | No | No | Present-but-unwired | No UI | High |
| Activity | Yes | Telemetry bridge + logs | Partial (dashboard stream) | Partial | Low | No | Partially working | No dedicated activity ops view | High |
| Traces | Yes | Stored via directive logs | No | Not proven | No | No | Missing in UI | No route | High |
| Audit | Yes | Audit events context | No | Not proven | No | No | Missing in UI | No route | High |
| Vault / Hibernate / Thaw | Yes | Persistence wrapper | No | Not proven | No | No | Present-but-unwired | No route/control | Critical |
| Pools | Yes | Mentioned deferred | No | No | No | No | Missing | Deferred docs | Medium |
| Schedules | Yes | Dynamic schedule config | Minimal page only | No | No | No | Partially wired | No cron controls | High |
| Hierarchy | Yes | Parent/child primitives referenced in plan | No | No | No | No | Missing | No route | High |
| Integrations | Yes | Integrations table schema | No | No | No | No | Missing | No route | Medium |
| Settings | Yes | Minimal page | Yes | No | Low | No | Partial shell | No settings controls | High |
| Ejector | Yes | Deferred | No | No | No | No | Missing | Deferred docs | Medium |
| Glossary | Yes | Not found | No | No | No | No | Missing | No route/docs surface | Low |
| Threads | Yes | Deferred in docs | No | No | No | No | Missing | No route | Medium |
| Memory | Yes | Deferred in docs | No | No | No | No | Missing | No route | Medium |
| Identities | Yes | Deferred in docs | No | No | No | No | Missing | No route | Medium |
| Block editors / Codegen | Yes | Codegen backend app | No | No | No | No | Present backend only | No block editor route | High |
| Debug panel | Yes | Runtime debug wrapper | No | Not proven | No | No | Present-but-unwired | No route | High |
| Error policy | Yes | Mentioned deferred | No | No | No | No | Missing | No UI/test evidence | High |
| Orphans / Adoption | Yes | Plan coverage | No | No | No | No | Missing | No route | Medium |

**Confidence:** 4/5 (**Tier B — Static-code verified**). Rationale: matrix statuses are grounded in inspected routes/modules/docs, with runtime-status columns kept conservative because checks were not executed.

---

# 10. Screen / Surface Audit

## Home
- Intended promise: manager dashboard with activity and metrics.
- Actual: heading + activity stream list.
- Works: subscribes and displays pushed events.
- Partial: no KPI cards, filters, ownership, SLA context.
- Breaks: no execution controls.
- Layman usable: limited.
- Expectation satisfied: no.

## Roster / Hire
- Intended: recruit pool, hire/fire/status.
- Actual: static heading and sentence.
- Works: route loads.
- Partial: none meaningful.
- Breaks: hire lifecycle absent.
- Layman usable: no.
- Expectation satisfied: no.

## Agent Detail
- Intended: actionable agent operations + state + debug.
- Actual: event stream for chosen id.
- Works: subscribes to topics.
- Partial: displays event/status only.
- Breaks: no state view, no controls.
- Layman usable: low.
- Expectation satisfied: no.

## Workflow Builder
- Intended: compose workflow graphs and run/inspect.
- Actual: title, description, workflow stream list.
- Works: PubSub stream updates.
- Partial: monitoring-only shell.
- Breaks: no composition/run controls.
- Layman usable: no.
- Expectation satisfied: no.

## Teams (Pods)
- Intended: pod topology and coordination.
- Actual: static text.
- Works: route render only.
- Partial: none.
- Breaks: no pod builder or actions.
- Layman usable: no.
- Expectation satisfied: no.

## Schedules
- Intended: cron/temporal orchestration.
- Actual: static text.
- Works: route render only.
- Partial: none.
- Breaks: no create/edit/cancel.
- Layman usable: no.
- Expectation satisfied: no.

## Settings
- Intended: runtime/debug/observability/integrations controls.
- Actual: static text.
- Works: route render only.
- Partial: none visible.
- Breaks: no actionable settings.
- Layman usable: no.
- Expectation satisfied: no.

**Confidence:** 4/5 (**Tier B — Static-code verified**). Rationale: each surface assessment comes from direct LiveView/router inspection, not runtime interaction.

---

# 11. Runtime / Execution Audit

- **Real Jido runtime integration:** exists in runtime wrappers (`Hiring`, `Signals`, `Persistence`, etc.); at least lifecycle wrapper behavior is unit/integration tested.  
- **Real agent lifecycle:** proven in runtime integration test only (start/list/count/whereis/stop).  
- **Real signals/directives/state ops:** modules exist, but UI-triggered execution not proven.  
- **Real observability:** telemetry bridge subscribes and persists logs; UI observability is minimal stream projection.  
- **Real persistence:** wrapper exists for hibernate/thaw + snapshot write path, not stakeholder-proven.  
- **Real pod/workflow behavior:** not established from UI.  
- **Real sensor behavior:** dynamic sensor host exists; no UX exposure/proof.  
- **Real codegen compile path:** backend pieces exist; no layman-facing block editor workflow demonstrated.

Overall runtime verdict: **developer-facing partial foundation, stakeholder-facing execution not proven end-to-end**.

**Confidence:** 3/5 (**Tier B — Static-code verified**). Rationale: runtime module presence is directly verified in code, but runtime behavior in this environment was not executed.

---

# 12. End-to-End Workflow Audit

Stakeholder story audit (create template -> hire -> assign -> observe -> understand -> organize -> trust):

1. **Create/select template**: breaks (no template UI route).
2. **Hire agent**: breaks at UI (runtime function exists, no control).
3. **Assign work**: breaks (no assignments surface).
4. **Observe execution**: partial (can only observe whatever events are broadcast; no causal task UI).
5. **Understand results**: breaks (no outcome summaries, no plain-language status model).
6. **Organize teams/pods**: breaks (teams page is static).
7. **Build workflows**: breaks (no workflow composer).
8. **Monitor ongoing operations**: partial but insufficient for managers.
9. **Trust actions are real**: not established; UI mostly headings and passive streams.

**Story break point:** step 1 for most users; step 2 even if seeded data exists.

**Confidence:** 3/5 (**Tier B — Static-code verified**). Rationale: breakpoints are inferred from absent UI paths and controls in code, without executing full user journeys.

---

# 13. Gap Register

## Product/UX/Runtime conformance gaps (ship blockers)

1. **G-001 — Core operator journey missing (Critical)**  
   Stakeholder impact: cannot hire/assign/manage agents.  
   Plan impact: violates core mission and no-code non-negotiable.  
   Evidence: Roster/Workflow/Teams/Schedules/Settings shells only.  
   Fix: implement actionable forms, runtime calls, and result feedback loop.

2. **G-002 — Massive capability-to-UI mismatch (Critical)**  
   Stakeholder impact: advertised breadth absent.  
   Plan impact: broad capability parity unmet.  
   Evidence: capability map/verification mostly `deferred`.  
   Fix: scope realistic MVP and remove unsupported claims until built.

3. **G-003 — Runtime modules unwired to UI (Critical)**  
   Stakeholder impact: backend exists but unusable.  
   Plan impact: execution path incomplete.  
   Evidence: no web references to core runtime modules.  
   Fix: wire LiveView events to runtime facades with robust error/UI state handling.

4. **G-004 — Truthfulness/documentation contradiction (High)**  
   Stakeholder impact: trust erosion in demos.  
   Plan impact: violates no-fiction requirement.  
   Evidence: scenario-certification advanced claims vs current tests/routes.  
   Fix: align docs to observed reality or implement claimed scenarios.

5. **G-005 — Observability not layman-operational (High)**  
   Stakeholder impact: cannot interpret work progression.  
   Plan impact: visible execution standard unmet.  
   Evidence: stream renders only event/status.  
   Fix: timeline cards, plain-language state transitions, links to actor/workflow, errors/remediation.

6. **G-006 — Missing critical surfaces (High)**  
   Stakeholder impact: no audit, traces, assignments, integrations, vault, hierarchy, threads/memory/identity.  
   Plan impact: broad conformance failure.  
   Evidence: router/nav limited to seven routes.  
   Fix: implement phased surfaces with minimum functional controls and proofs.

7. **G-007 — Validation evidence weak for stakeholder outcomes (Medium)**  
   Stakeholder impact: false confidence from render-only tests.  
   Plan impact: testability standard unmet.  
   Evidence: LiveView and Playwright tests assert headings/text visibility.  
   Fix: add E2E assertions for real action->runtime->UI outcome chain.

## Audit reproducibility/environment risks (non-product blockers)

1. **G-008 — Environment/bootstrap fragility (Medium)**  
   Stakeholder impact: audit and demo reproducibility risk in locked networks.  
   Plan impact: operational readiness risk.  
   Evidence: dependency fetch blocked in this environment.  
   Clarification: this does not reduce the validity of purely static findings, but it does block runtime confirmation in this environment.  
   Fix: provide vendor/cache strategy or offline dependency mirror guidance.



**Evidence anchors**
- G-001 (core operator journey missing):  
  Paths: `builder/apps/jido_builder_web/lib/jido_builder_web/live/roster_live.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/workflow_builder_live.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/teams_live.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/schedules_live.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/settings_live.ex`  
  Identifiers: `render/1`, `page_title` assigns  
  Distinctive string: `Roster / Hire Wizard`
- G-002 (capability-to-UI mismatch):  
  Paths: `builder/docs/capability_map.md`; `builder/docs/verification.md`; `builder/apps/jido_builder_web/lib/jido_builder_web/router.ex`  
  Identifiers: capability rows with `deferred`; router `live/3` entries  
  Distinctive string: `GAP-MVP-`
- G-003 (runtime modules unwired to UI):  
  Paths: `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/hiring.ex`; `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/signals.ex`; `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/persistence.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/`  
  Identifiers: runtime facade modules vs LiveView `handle_event/3` presence/absence  
  Distinctive string: `defmodule JidoBuilderRuntime.Signals do`
- G-004 (truthfulness/docs contradiction):  
  Paths: `builder/docs/scenario_certification.md`; `builder/apps/jido_builder_web/lib/jido_builder_web/router.ex`; `builder/e2e/tests/`  
  Identifiers: scenario completion statements; available routes; e2e assertion targets  
  Distinctive string: `Scenario`
- G-005 (observability not layman-operational):  
  Paths: `builder/apps/jido_builder_web/lib/jido_builder_web/live/dashboard_live.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/agent_live.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/live/workflow_builder_live.ex`  
  Identifiers: stream rendering helpers for event/status output  
  Distinctive string: `event_name`
- G-006 (critical surfaces missing):  
  Paths: `builder/apps/jido_builder_web/lib/jido_builder_web/router.ex`; `builder/apps/jido_builder_web/lib/jido_builder_web/components/layouts/root.html.heex`  
  Identifiers: route list and nav link set  
  Distinctive string: `href={~p"/teams"}`
- G-007 (validation evidence weak for outcomes):  
  Paths: `builder/apps/jido_builder_web/test/`; `builder/e2e/tests/`  
  Identifiers: LiveView render assertions, Playwright text checks  
  Distinctive string: `assert html =~`
- G-008 (bootstrap fragility in restricted network):  
  Paths: `builder/docs/post_build_audit_2026-04-11.md`; `mix.exs`  
  Identifiers: execution-attempt note; dependency declarations requiring Hex fetch  
  Distinctive string: `HTTP 403 through tunnel`

**Confidence:** 4/5 (**Tier B — Static-code verified**). Rationale: all gaps are tied to concrete source evidence; severity/impact is still an audit judgment.

---

# 14. Priority Fix Plan

## Critical before any stakeholder demo
1. Remove/flag non-functional labels and docs that imply unavailable controls.
2. Implement the single truth path: **Hire agent -> assign signal -> observe progress -> stop agent** entirely from UI.
3. Add explicit runtime outcome panels (success/error/details/next action) for layman users.
4. Add minimum Activity + Audit screen with human-readable event semantics.

## High priority for product credibility
1. Deliver real Workflow Builder MVP (create steps, run workflow, inspect per-step status).
2. Deliver Teams/Pods MVP (create team, add members, broadcast, observe fan-out).
3. Deliver Schedules MVP (create/cancel cron with observable agent receipt).
4. Wire debug controls and error policy basics into UI with safe defaults.

## Medium priority for completeness
1. Templates/Skills/Discovery surfaces.
2. Vault/hibernate/thaw with continuity visualization.
3. Integrations/Settings operational controls.
4. Threads/Memory/Identity read views.

## Lower priority polish
1. Advanced codegen/block editor UX.
2. Ejector/export tooling.
3. Glossary and in-product onboarding walkthrough.

**For each critical gap, observable fix proof required**
- User can complete flow unaided.
- Runtime event generated and visible.
- Final state and audit entry visible in UI.
- No hidden CLI/Elixir steps needed.

**Confidence:** 3/5 (**Tier C — Inferred**). Rationale: prioritization is a prescriptive recommendation based on observed gaps, not a directly verifiable code fact.

---

# 15. Ship / No-Ship Recommendation

**Recommendation: No-Ship**

This build should not be presented as the intended Builder to layman stakeholders. Evidence suggests a scaffolded foundation with partial runtime plumbing, but not a credible no-code operational product. At most, it can be positioned internally as a technical baseline/prototype with explicit caveats: “navigation shell + event stream proof-of-concept, major operator capabilities deferred.” Ship decision should change only after the critical path (hire -> assign -> observe -> manage) is demonstrably complete in UI and documented claims are brought into strict alignment with implementation truth.

**Confidence:** 4/5 (**Tier B — Static-code verified**). Rationale: recommendation is strongly supported by static evidence, with runtime confidence intentionally limited due non-executed checks.
