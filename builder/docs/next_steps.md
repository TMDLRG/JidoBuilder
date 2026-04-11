# Next Steps

## Immediate

1. Convert `jido_builder_web` from plain Mix app to Phoenix LiveView app.
2. Add umbrella configuration (`dev/test/prod`) for Repo, PubSub, and runtime services.
3. Add initial `jido_builder_core` schemas + migrations for templates, agents, and audit logs.
4. Implement runtime service skeleton: hiring, signal dispatch, directive/state-op emitters.
5. Execute MVP slices in backlog-ID order and update `capability_map.md` + `verification.md` per merge.

## Explicit deferred backlog IDs (not delivered in MVP baseline branch)

- `GAP-MVP-001` — Agent lifecycle UI and runtime wiring (`start/stop/list/count/whereis`, dynamic template schema).
- `GAP-MVP-002` — Assignment composer + signal dispatch + directive execution pipeline.
- `GAP-MVP-003` — Discovery catalog surfaces (actions/agents/plugins/sensors/demos + refresh).
- `GAP-MVP-004` — Persistence vault workflows (`hibernate/thaw`, storage adapters, snapshot metadata).
- `GAP-MVP-005` — State-operations editor and runtime applicator (all five `StateOp` variants).
- `GAP-MVP-006` — Scheduling UX and runtime hooks (cron, delayed schedule, timeout/signal actions).
- `GAP-MVP-007` — Observability stack (telemetry bridge, logs, traces, metrics, debug controls).
- `GAP-MVP-008` — Plugins and sensors UX + runtime host + custom extension path.
- `GAP-MVP-009` — Hierarchy/coordination surfaces (`Await.*`, parent/child controls, parent binding).
- `GAP-MVP-010` — Codegen block editor and compile pipeline (custom agents/actions/strategies, igniter reuse).
- `GAP-MVP-011` — Error-policy and status management workflows.
- `GAP-MVP-012` — Pods topology editor and pod action workflows.
- `GAP-MVP-013` — Threads, memory, and identity feature surfaces.
- `GAP-MVP-014` — Worker-pool configuration and runtime checkout behavior.
- `GAP-MVP-015` — Workspace multi-tenancy and partition-safe operations.
- `GAP-MVP-016` — Creator-level testing and replay features.
- `GAP-MVP-017` — Configuration surfaces (instance/debug/observability/redaction).
- `GAP-MVP-018` — Ejector exports (template/action/pod Elixir output).
