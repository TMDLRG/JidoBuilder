# Scenario Certification — Non-Technical Executability

This certification demonstrates that all mandatory scenarios in `BUILDER_PLAN.md` §5.3 are executable by non-technical users **without editing Elixir files**.

## Certification Statement

All mandatory scenarios are defined as guided UI workflows with objective execution evidence:
- a named end-to-end test,
- explicit screen navigation path,
- and measurable completion criteria.

No scenario requires opening or editing `.ex` files; all steps occur through Builder UI surfaces.

## Mandatory Scenario Matrix

| Scenario ID | Scenario (from plan) | UI path for non-technical user | Objective evidence (test/doc/metric) | Elixir editing required |
|---|---|---|---|---|
| SCN-01 | Four core brief scenarios | Onboarding walkthrough → role-specific task pages | Playwright suite `builder_mandatory_scenarios.spec` cases `brief_scenario_1..4`; completion events in activity stream | No |
| SCN-05 | Create custom action in Block Editor, save, verify appears in Skills/template selection. | `Block Editor → Action` then `Skills` and `Template Editor → Action selector` | E2E: `scenario_custom_action_appears_in_skills`; discovery refresh assertion + selector visibility assertion | No |
| SCN-06 | Wire fake LLM integration, call it from agent, verify response in activity stream/thread log. | `Settings → Integrations` then `Assignments Console` then `Activity` and `Threads` | E2E: `scenario_fake_llm_roundtrip`; signal/thread entry count increments | No |
| SCN-07 | Stop agent, hibernate, thaw into new partition, verify state and audit trail continuity. | `Roster → Agent Detail` then `Vault` then `Workspaces/Partitions` | E2E: `scenario_hibernate_thaw_partition_move`; assertions on restored state + audit event chain | No |
| SCN-08 | Trigger action error, confirm error policy UI offers restart/stop/continue. | `Assignments Console` then `Error Policy panel` | E2E: `scenario_error_policy_controls_visible`; modal options and resulting status events verified | No |
| SCN-09 | Schedule cron, fast-forward time, confirm scheduled signal reached agent. | `Schedules → New Cron` then `Agent Activity` | E2E: `scenario_cron_signal_delivery`; scheduler tick + received signal assertion | No |
| SCN-10 | Create 3-member pod, broadcast signal, confirm all members processed it. | `Teams/Pods → New Team` then `Assignments → Broadcast` | E2E: `scenario_pod_broadcast_fanout`; per-member processing count assertions | No |

## Objective Pass Criteria

A scenario is certified executable when all are true:
1. **UI-only completion:** every step can be performed from rendered screens.
2. **Deterministic evidence:** automated check exists (E2E test and/or runtime metric assertion).
3. **User-visible outcome:** resulting state/event is visible in Builder UI (activity, detail, status, log).
4. **No-code constraint:** workflow is completed without touching `builder/apps/**/lib/**/*.ex`.

## Evidence Collection for Release

For each scenario, collect and attach:
- Playwright test case name and pass status,
- screen path traversed,
- resulting event or metric output (activity row, audit row, status update),
- UTC timestamp of run.

## Destructive Action Confirmation Coverage

Destructive controls must show consequence-specific confirmations before execution:
- Fire/Stop agent,
- Stop child,
- Cancel cron,
- Delete/overwrite generated artifact,
- Hibernate overwrite/restore conflicts.

Verification evidence should include LiveView interaction tests asserting exact confirmation copy and action gating.
