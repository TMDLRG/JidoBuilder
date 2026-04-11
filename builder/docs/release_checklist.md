# Builder Release Checklist (Definition of Done Evidence Map)

This checklist maps each **Definition of Done** bullet in `BUILDER_PLAN.md` §11 to objective, reviewable evidence.

## Evidence Matrix

| DoD bullet (`BUILDER_PLAN.md` §11) | Objective evidence type | Objective evidence |
|---|---|---|
| `cd builder && mix deps.get && mix ecto.setup && mix phx.server` launches app at `http://localhost:4000`. | Run command + startup log | Runbook command sequence in `builder/docs/run.md` under “Quickstart”, plus Phoenix boot confirmation output (`[info] Running JidoBuilderWeb.Endpoint`). |
| Every row in Section 7 has a status + confidence rating in `builder/docs/verification.md`. | Doc section completeness | `builder/docs/verification.md` “Verification Matrix” table: each row includes **Status** and **Confidence** columns. |
| A non-technical user can complete all mandatory scenarios without editing Elixir. | Scenario certification doc + E2E test names + UI paths | `builder/docs/scenario_certification.md` (final certification matrix) with scenario IDs, screen path walkthroughs, and executable E2E test names. |
| `mix test` at umbrella root is green across all five apps. | Test command output | Umbrella root CI/local command: `cd builder && mix test`; attach pass/fail transcript in release artifacts. |
| Every destructive action has a confirmation with specific consequences. | UI route inventory + component screenshot/test | Confirmation coverage table in scenario certification appendix (“destructive action confirmations”), plus LiveView interaction tests under `jido_builder_web` for confirm modals/messages. |
| No screen renders fake data or unwired controls. | E2E assertions + integration checks | Playwright spec assertions for enabled controls and real backend effects; integration tests verifying data mutations (`signals_log`, `directives_log`, lifecycle state). |
| `builder/docs/run.md` lets another engineer run the app in under five minutes from a clean clone. | Time-boxed reproducibility check | Fresh-clone timed run validation recorded in release notes with start/end timestamps and exact command sequence from `builder/docs/run.md`. |
| Every Jido primitive from Section 0.3 is exposed in UI, documented as abstraction, or listed in `next_steps.md` with gap ID. | Cross-document traceability | `builder/docs/verification.md` rows map primitives to status and blockers; deferred items must reference explicit `GAP-*` entries in `builder/docs/next_steps.md`. |

## Release Gate Steps

1. Run boot smoke test exactly as documented in `builder/docs/run.md`.
2. Run umbrella tests: `cd builder && mix test`.
3. Review `builder/docs/verification.md` for status/confidence completeness.
4. Review `builder/docs/scenario_certification.md` for non-technical execution proof.
5. Validate deferred primitives are cross-linked to explicit `GAP-*` IDs in `builder/docs/next_steps.md`.
6. Confirm changelog entry includes conventional commit summaries and user-visible impact notes.

## Sign-off Template

- Release candidate: `____________`
- Verifier: `____________`
- Date (UTC): `____________`
- Boot smoke test: ☐ pass ☐ fail
- Umbrella tests: ☐ pass ☐ fail
- Scenario certification: ☐ pass ☐ fail
- Primitive coverage traceability: ☐ pass ☐ fail
- Final decision: ☐ ship ☐ hold
