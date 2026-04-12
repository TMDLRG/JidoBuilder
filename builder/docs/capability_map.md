# Builder Capability Map

Status legend: `done` = implemented in this branch, `deferred` = explicitly postponed beyond MVP.

| Capability | UI surface | Path (A/B/hybrid) | Exact Jido primitive | Status | Confidence | Blocker/Gap ID (if deferred) |
|---|---|---|---|---|---:|---|
| Umbrella app boundaries | Internal platform | hybrid | Builder umbrella architecture (`builder/apps/*`) | done | 5 | — |
| Cloak key rotation | Mix task `jido_builder.rotate_cloak_key` | hybrid | `JidoBuilderCore.Vault.reconfigure/1` + SQLite-safe row re-encryption | done | 5 | — |
| Path-allowlist fuzz (Phase 5 gate) | Internal codegen sandbox | hybrid | `FileWriter.resolve_path/1` — 1000-run StreamData property fuzz | done | 5 | — |
| EEx template fuzz (Phase 5 gate) | Internal codegen templates | hybrid | All 5 templates: module-name validation + `inspect(description)` — 1000-run StreamData property fuzz | done | 5 | — |
| Local single-user auth | `/login` LiveView + `POST /login` + `on_mount` hook | hybrid | `JidoBuilderCore.Accounts` (PBKDF2) + `JidoBuilderWeb.UserAuth` session plug/hook (`/healthz`/`/readyz` bypassed) | done | 5 | — |
| Start agent | Roster → Hire wizard | A | `JidoBuilderRuntime.Roster.hire/3` → `Hiring.start/3` → `Jido.start_agent/3` | done | 5 | — |
| Stop agent | Roster → Stop + confirm modal | A | `JidoBuilderRuntime.Roster.stop/3` → `Hiring.stop/2` → `Jido.stop_agent/3` | done | 5 | — |
| List running agents | Roster index stream | A | `Roster.list/1` — reads `agent_instances` with status "running" | done | 5 | — |
| Whereis by ID | Assignments console → target select | A | `Hiring.whereis/2` → `Jido.whereis/3` | done | 5 | — |
| Sync signal send | Assignments console (cast path) | A | `Signals.cast/3` → `Jido.AgentServer.cast/2` | done | 5 | — |
| Build CloudEvent signal | Assignments console | A | `Signals.new/4` → `Jido.Signal.new!/2` | done | 5 | — |
| Live telemetry stream | Activity stream — DashboardLive | A | `TelemetryBridge` → PubSub → `DashboardLive.handle_info` | done | 5 | — |
| Rate limit on /assignments | Assignments console — 7.14 | hybrid | `Hammer.check_rate/3` (ETS backend, 10 req/min per user) | done | 5 | — |
| Activity event translation | Home dashboard stream rows | hybrid | `Observability.translate_event/1` — plain-English labels replacing raw event names | done | 5 | — |
| App shell navigation | App layout nav + Cmd+K palette | A | Layout `app.html.heex` — nav links to all routes + command palette container | done | 5 | — |
| Home KPIs | Dashboard running-agents counter | A | `Roster.list/1` count, live-updated via PubSub roster events | done | 5 | — |
| Templates Library | `/templates` index | A | `Templates.list_templates/1` → stream-rendered list | done | 5 | — |
| Template Editor | `/templates/:id/edit` form | A | `Templates.update_template/3` → Ecto changeset persist | done | 5 | — |
| Agent Detail state | `/agents/:id` state + event stream | A | `AgentInstance` DB lookup + `Observability.translate_event/1` stream | done | 5 | — |
| Skills catalog | `/skills` discovery actions list | A | `Discovery.list_actions/1` → rendered list | done | 5 | — |
| Work Styles picker | `/work-styles` strategy list | A | Static `Direct`/`FSM` strategies rendered | done | 5 | — |
| Directives Builder | `/directives` all 11 types | A | Static directive type catalog rendered | done | 5 | — |
| Structured JSON logger | Prod logger config | hybrid | OTP 27+ `:logger_formatter` JSON in `config/prod.exs` | done | 4 | — |
| Prometheus /metrics | `/metrics` endpoint (no auth) | A | `TelemetryMetricsPrometheus.Core.scrape/0` on API scope | done | 5 | — |
| Start agent | Roster → Hire wizard | A | `Jido.start_agent/3` | deferred | 3 | GAP-MVP-001 |
| Stop agent | Roster → Fire | A | `Jido.stop_agent/2` | deferred | 3 | GAP-MVP-001 |
| List running agents | Roster index | A | `Jido.list_agents/2` | deferred | 3 | GAP-MVP-001 |
| Count agents | Home dashboard | A | `Jido.agent_count/2` | deferred | 3 | GAP-MVP-001 |
| Whereis by ID | Agent detail | A | `Jido.whereis/3` | deferred | 3 | GAP-MVP-001 |
| Hibernate agent | Vault | A | `Jido.hibernate/2` | done | 4 | — |
| Thaw agent | Vault | A | `Jido.thaw/3` | done | 4 | — |
| Toggle debug | Debug panel | A | `Jido.debug/0,1,2` | done | 4 | — |
| Recent debug events | Debug panel | A | `Jido.recent/1,2` | done | 4 | — |
| Debug status | Debug panel | A | `Jido.debug_status/0` | done | 4 | — |
| Parent binding | Hierarchy view | A | `Jido.parent_binding/2,3` | done | 4 | — |
| Sync signal send | Assignment composer | A | `Jido.AgentServer.call/2,3` | deferred | 3 | GAP-MVP-002 |
| Async signal send | Assignment composer | A | `Jido.AgentServer.cast/2` | deferred | 3 | GAP-MVP-002 |
| Read agent state | Agent detail | A | `Jido.AgentServer.state/1` | deferred | 3 | GAP-MVP-002 |
| Agent recent events | Agent detail | A | `Jido.AgentServer.recent_events/2` | deferred | 3 | GAP-MVP-007 |
| Per-agent debug toggle | Agent detail | A | `Jido.AgentServer.set_debug/2` | deferred | 3 | GAP-MVP-007 |
| List actions catalog | Skills index | A | `Jido.Discovery.list_actions/1` | deferred | 4 | GAP-MVP-003 |
| List agents catalog | Template picker | A | `Jido.Discovery.list_agents/1` | deferred | 4 | GAP-MVP-003 |
| List sensors catalog | Watchers index | A | `Jido.Discovery.list_sensors/1` | deferred | 4 | GAP-MVP-003 |
| List plugins catalog | Capability Packs index | A | `Jido.Discovery.list_plugins/1` | deferred | 4 | GAP-MVP-003 |
| List demos catalog | Demos index | A | `Jido.Discovery.list_demos/1` | deferred | 4 | GAP-MVP-003 |
| Lookup action by slug | Skill detail | A | `Jido.Discovery.get_action_by_slug/1` | deferred | 4 | GAP-MVP-003 |
| Refresh discovery | Runtime/codegen bridge | hybrid | `Jido.Discovery.refresh/0` | deferred | 4 | GAP-MVP-003 |
| Catalog snapshot | Admin diagnostics | A | `Jido.Discovery.catalog/0` | deferred | 4 | GAP-MVP-003 |
| Async discovery init | Runtime startup | A | `Jido.Discovery.init_async/0` | deferred | 4 | GAP-MVP-003 |
| Build CloudEvent signal | Assignment composer | A | `Jido.Signal.new!/2,3` | deferred | 4 | GAP-MVP-002 |
| Directive Emit | Directive builder | A | `Jido.Agent.Directive.Emit` / `Directive.emit/1,2` | deferred | 4 | GAP-MVP-002 |
| Directive Error | Directive builder | A | `Jido.Agent.Directive.Error` / `Directive.error/1` | deferred | 4 | GAP-MVP-002 |
| Directive Spawn | Directive builder | A | `Jido.Agent.Directive.Spawn` / `Directive.spawn/1` | deferred | 4 | GAP-MVP-002 |
| Directive SpawnAgent | Directive builder | A | `Jido.Agent.Directive.SpawnAgent` / `Directive.spawn_agent/2,3` | deferred | 4 | GAP-MVP-002 |
| Directive AdoptChild | Hierarchy view | A | `Jido.Agent.Directive.AdoptChild` / `Directive.adopt_child/2,3` | deferred | 4 | GAP-MVP-009 |
| Directive StopChild | Hierarchy view | A | `Jido.Agent.Directive.StopChild` / `Directive.stop_child/1,2` | deferred | 4 | GAP-MVP-009 |
| Directive Schedule | Schedules | A | `Jido.Agent.Directive.Schedule` / `Directive.schedule/2` | deferred | 4 | GAP-MVP-006 |
| Directive RunInstruction | Directive builder | A | `Jido.Agent.Directive.RunInstruction` / `Directive.run_instruction/2` | deferred | 4 | GAP-MVP-010 |
| Directive Stop | Roster | A | `Jido.Agent.Directive.Stop` / `Directive.stop/0,1` | deferred | 4 | GAP-MVP-001 |
| Directive Cron | Schedules | A | `Jido.Agent.Directive.Cron` / `Directive.cron/2,3` | done | 4 | — |
| Directive CronCancel | Schedules | A | `Jido.Agent.Directive.CronCancel` / `Directive.cron_cancel/1` | done | 4 | — |
| StateOp SetState | State ops editor | A | `Jido.Agent.StateOp.SetState` | done | 5 | — |
| StateOp ReplaceState | State ops editor | A | `Jido.Agent.StateOp.ReplaceState` | done | 5 | — |
| StateOp DeleteKeys | State ops editor | A | `Jido.Agent.StateOp.DeleteKeys` | done | 5 | — |
| StateOp SetPath | State ops editor | A | `Jido.Agent.StateOp.SetPath` | done | 5 | — |
| StateOp DeletePath | State ops editor | A | `Jido.Agent.StateOp.DeletePath` | done | 5 | — |
| Control Broadcast | Assignments | A | `Jido.Actions.Control.Broadcast` | deferred | 3 | GAP-MVP-002 |
| Control Cancel | Roster | A | `Jido.Actions.Control.Cancel` | deferred | 3 | GAP-MVP-009 |
| Control Forward | Playbook step | A | `Jido.Actions.Control.Forward` | deferred | 3 | GAP-MVP-009 |
| Control Noop | Block utility | A | `Jido.Actions.Control.Noop` | deferred | 3 | GAP-MVP-010 |
| Control Reply | Assignments | A | `Jido.Actions.Control.Reply` | deferred | 3 | GAP-MVP-002 |
| Lifecycle NotifyParent | Hierarchy | A | `Jido.Actions.Lifecycle.NotifyParent` | deferred | 3 | GAP-MVP-009 |
| Lifecycle NotifyPid | Advanced assignment | A | `Jido.Actions.Lifecycle.NotifyPid` | deferred | 3 | GAP-MVP-009 |
| Lifecycle SpawnChild | Hierarchy | A | `Jido.Actions.Lifecycle.SpawnChild` | deferred | 3 | GAP-MVP-009 |
| Lifecycle StopChild | Hierarchy | A | `Jido.Actions.Lifecycle.StopChild` | deferred | 3 | GAP-MVP-009 |
| Lifecycle StopSelf | Roster | A | `Jido.Actions.Lifecycle.StopSelf` | deferred | 3 | GAP-MVP-001 |
| Scheduling CancelCron | Schedules | A | `Jido.Actions.Scheduling.CancelCron` | deferred | 3 | GAP-MVP-006 |
| Scheduling ScheduleCron | Schedules | A | `Jido.Actions.Scheduling.ScheduleCron` | deferred | 3 | GAP-MVP-006 |
| Scheduling ScheduleSignal | Schedules | A | `Jido.Actions.Scheduling.ScheduleSignal` | deferred | 3 | GAP-MVP-006 |
| Scheduling ScheduleTimeout | Template timeout | A | `Jido.Actions.Scheduling.ScheduleTimeout` | deferred | 3 | GAP-MVP-006 |
| Status MarkCompleted | Runtime status | A | `Jido.Actions.Status.MarkCompleted` | deferred | 3 | GAP-MVP-011 |
| Status MarkFailed | Runtime status | A | `Jido.Actions.Status.MarkFailed` | deferred | 3 | GAP-MVP-011 |
| Status MarkIdle | Runtime status | A | `Jido.Actions.Status.MarkIdle` | deferred | 3 | GAP-MVP-011 |
| Status MarkWorking | Runtime status | A | `Jido.Actions.Status.MarkWorking` | deferred | 3 | GAP-MVP-011 |
| Status SetStatus | Advanced status | A | `Jido.Actions.Status.SetStatus` | deferred | 3 | GAP-MVP-011 |
| Strategy Direct | Work styles / Strategy editor | A | `Jido.Agent.Strategy.Direct` | done | 4 | — |
| Strategy FSM | Work styles / FSM Designer | hybrid | `Jido.Agent.Strategy.FSM` | done | 4 | — |
| Pod behavior support | Teams | A | `Jido.Pod` | done | 4 | — |
| Pod topology support | Teams topology | A | `Jido.Pod.Topology` | done | 4 | — |
| Pod get | Teams detail | A | `Jido.Pod.get/2,3` | deferred | 3 | GAP-MVP-012 |
| Pod ensure node | Teams detail | A | `Jido.Pod.ensure_node/3` | deferred | 3 | GAP-MVP-012 |
| Pod mutate | Teams editor | A | `Jido.Pod.mutate/3` | deferred | 3 | GAP-MVP-012 |
| Pod action mutate | Teams actions | A | `Jido.Pod.Actions.Mutate` | deferred | 3 | GAP-MVP-012 |
| Pod action evolve | Teams actions | A | `Jido.Pod.Actions.Evolve` | deferred | 3 | GAP-MVP-012 |
| Instance lifecycle registry | Runtime infra | A | `Jido.Agent.InstanceManager` | done | 3 | — |
| Plugin behavior | Capability packs | hybrid | `Jido.Plugin` | done | 4 | — |
| Plugin spec/config/manifest/requirements/routes/schedules/instance | Capability packs advanced | hybrid | `Jido.Plugin.Spec`, `Config`, `Manifest`, `Requirements`, `Routes`, `Schedules`, `Instance` | deferred | 2 | GAP-MVP-008 |
| Sensor behavior | Watchers | hybrid | `Jido.Sensor` | done | 4 | — |
| Sensor runtime | Watchers runtime | A | `Jido.Sensor.Runtime` | deferred | 3 | GAP-MVP-008 |
| Sensor spec | Watchers editor | A | `Jido.Sensor.Spec` | deferred | 3 | GAP-MVP-008 |
| Heartbeat sensor | Watchers | A | `Jido.Sensors.Heartbeat` | deferred | 3 | GAP-MVP-008 |
| Bus sensor | Watchers | A | `Jido.Sensors.Bus` | deferred | 3 | GAP-MVP-008 |
| Storage ETS | Settings storage | A | `Jido.Storage.ETS` | deferred | 3 | GAP-MVP-004 |
| Storage File | Settings storage | A | `Jido.Storage.File` | deferred | 3 | GAP-MVP-004 |
| Storage Redis | Settings storage | A | `Jido.Storage.Redis` | deferred | 2 | GAP-MVP-004 |
| Persist API | Vault and snapshots | A | `Jido.Persist` | deferred | 3 | GAP-MVP-004 |
| Thread core | Threads explorer | A | `Jido.Thread` | done | 3 | — |
| Thread agent | Threads | A | `Jido.Thread.Agent` | deferred | 2 | GAP-MVP-013 |
| Thread entry | Threads | A | `Jido.Thread.Entry` | deferred | 2 | GAP-MVP-013 |
| Thread plugin | Template plugins | A | `Jido.Thread.Plugin` | deferred | 2 | GAP-MVP-013 |
| Thread store | Threads | A | `Jido.Thread.Store` | deferred | 2 | GAP-MVP-013 |
| Thread adapter in-memory | Threads settings | A | `Jido.Thread.Store.Adapters.InMemory` | deferred | 2 | GAP-MVP-013 |
| Thread adapter journal-backed | Threads settings | A | `Jido.Thread.Store.Adapters.JournalBacked` | deferred | 2 | GAP-MVP-013 |
| Memory core | Memory spaces | A | `Jido.Memory` | done | 3 | — |
| Memory agent | Memory | A | `Jido.Memory.Agent` | deferred | 2 | GAP-MVP-013 |
| Memory plugin | Template plugins | A | `Jido.Memory.Plugin` | deferred | 2 | GAP-MVP-013 |
| Memory space | Memory spaces | A | `Jido.Memory.Space` | deferred | 2 | GAP-MVP-013 |
| Identity core | Identity profiles | A | `Jido.Identity` | done | 3 | — |
| Identity agent | Identity | A | `Jido.Identity.Agent` | deferred | 2 | GAP-MVP-013 |
| Identity plugin | Template plugins | A | `Jido.Identity.Plugin` | deferred | 2 | GAP-MVP-013 |
| Identity profile | Identity profiles | A | `Jido.Identity.Profile` | deferred | 2 | GAP-MVP-013 |
| Observe facade | Activity/metrics | A | `Jido.Observe` | deferred | 3 | GAP-MVP-007 |
| Observe config | Settings observability | A | `Jido.Observe.Config` | deferred | 3 | GAP-MVP-007 |
| Event contract | Event schema validation | A | `Jido.Observe.EventContract` | deferred | 3 | GAP-MVP-007 |
| Tracing context | Traces screen | A | `Jido.Tracing.Context` | deferred | 3 | GAP-MVP-007 |
| Trace model | Traces screen | A | `Jido.Tracing.Trace` | deferred | 3 | GAP-MVP-007 |
| Workflow Builder (D3 DAG) | `/workflows` + `workflow_dag.js` | hybrid | `Workflows.create_workflow_step/2` + `pushEvent("init_graph")` | done | 4 | — |
| Scheduler | Schedules | A | `Jido.Scheduler` | done | 4 | — |
| Scheduler job | Schedules | A | `Jido.Scheduler.Job` | done | 4 | — |
| SQLite WAL-aware backup | `infra/backup.sh` | hybrid | `sqlite3 <db> ".backup <dest>"` — WAL-safe online backup | done | 5 | — |
| Await completion | Assignments | A | `Jido.Await.completion/2,3` | deferred | 3 | GAP-MVP-009 |
| Await child | Hierarchy | A | `Jido.Await.child/3,4` | deferred | 3 | GAP-MVP-009 |
| Await all | Playbooks | A | `Jido.Await.all/2,3` | deferred | 3 | GAP-MVP-009 |
| Await any | Playbooks | A | `Jido.Await.any/2,3` | deferred | 3 | GAP-MVP-009 |
| Await alive | Roster badges | A | `Jido.Await.alive?/1` | deferred | 3 | GAP-MVP-009 |
| Await cancel | Roster | A | `Jido.Await.cancel/1,2` | deferred | 3 | GAP-MVP-009 |
| Await get children | Hierarchy | A | `Jido.Await.get_children/1` | deferred | 3 | GAP-MVP-009 |
| Await get child | Hierarchy | A | `Jido.Await.get_child/2` | deferred | 3 | GAP-MVP-009 |
| Worker pools | Pools settings | A | `Jido.Agent.WorkerPool` | deferred | 2 | GAP-MVP-014 |
| Debug module levels | Settings/debug panel | A | `Jido.Debug` | deferred | 3 | GAP-MVP-007 |
| Igniter helper reuse | Codegen internals | B | `Jido.Igniter.Helpers` | deferred | 2 | GAP-MVP-010 |
| Igniter templates reuse | Codegen internals | B | `Jido.Igniter.Templates` | deferred | 2 | GAP-MVP-010 |
| Define agent schema | Template editor | A | Dynamic agent config (Builder abstraction over `Jido.Agent`) | deferred | 3 | GAP-MVP-001 |
| Agent before hook | Template hooks advanced | B | Generated module hook (`on_before_cmd`) | deferred | 2 | GAP-MVP-010 |
| Agent after hook | Template hooks advanced | B | Generated module hook (`on_after_cmd`) | deferred | 2 | GAP-MVP-010 |
| Fully custom agent | Block editor | B | Generated agent module | deferred | 2 | GAP-MVP-010 |
| Execute action | Assignments console | A | `Jido.Exec.run/3` via dispatch | deferred | 3 | GAP-MVP-002 |
| Define custom action | Block editor | B | Generated action module | deferred | 2 | GAP-MVP-010 |
| Action filter by category/tag | Skills filters | A | Discovery filter options | deferred | 2 | GAP-MVP-003 |
| Execute with timeout/retries | Assignments advanced | A | `cmd/3` options | deferred | 2 | GAP-MVP-002 |
| Register compiled module in discovery | Compile pipeline | B | `Jido.Discovery.refresh/0` | deferred | 2 | GAP-MVP-010 |
| Define agent routes | Template routes | A | Signal routes field | deferred | 3 | GAP-MVP-002 |
| Define plugin routes | Capability pack routes | A | Plugin routes rows | deferred | 3 | GAP-MVP-008 |
| Define strategy routes | Work style advanced | B | Generated strategy `signal_routes/1` | deferred | 2 | GAP-MVP-010 |
| Wildcard signal patterns | Route editor | A | Plugin `signal_patterns` | deferred | 2 | GAP-MVP-008 |
| CloudEvents advanced fields | Assignment advanced | A | `Jido.Signal` struct fields | deferred | 3 | GAP-MVP-002 |
| Declarative schedules | Template schedules | A | `schedules:` option | deferred | 3 | GAP-MVP-006 |
| Snapshot metadata | Vault snapshots | A | Builder snapshots table over `Jido.Persist` | deferred | 2 | GAP-MVP-004 |
| Workspace partition key | Workspaces | A | `Jido.partition_key/2` | deferred | 2 | GAP-MVP-015 |
| Partition-scoped list | Workspace dashboard | A | `list_agents(partition: ...)` | deferred | 2 | GAP-MVP-015 |
| Partition-safe hibernate | Workspace vault | A | `hibernate(partition: ...)` | deferred | 2 | GAP-MVP-015 |
| Pool definition | Pools | A | `agent_pools` config | deferred | 2 | GAP-MVP-014 |
| Pool size/max_overflow | Pools edit | A | pool config (`size`, `max_overflow`) | deferred | 2 | GAP-MVP-014 |
| Checkout pool on hire | Hire flow | A | `Jido.Agent.WorkerPool` | deferred | 2 | GAP-MVP-014 |
| Live telemetry stream | Activity screen | A | `[:jido, ...]` telemetry events | deferred | 3 | GAP-MVP-007 |
| Per-agent events stream | Agent detail | A | `recent_events/2` | deferred | 3 | GAP-MVP-007 |
| Debug ring buffer view | Debug panel | A | `recent_events/2`/`Jido.recent/1,2` | deferred | 3 | GAP-MVP-007 |
| Signal log | Activity filters | A | Builder `signals_log` (from telemetry) | deferred | 2 | GAP-MVP-007 |
| Directive log | Directive view | A | Builder `directives_log` (from telemetry) | deferred | 2 | GAP-MVP-007 |
| Metrics rollups | Home dashboard | A | telemetry metrics rollups | deferred | 2 | GAP-MVP-007 |
| Error policy editor | Error policy UI | A | `Jido.AgentServer.ErrorPolicy` | deferred | 2 | GAP-MVP-011 |
| Restart strategy | Template restart | A | `restart:` option | deferred | 2 | GAP-MVP-011 |
| Stop-on-error policy | Template error policy | A | Policy config | deferred | 2 | GAP-MVP-011 |
| Testing template cmd purity | Template “Test this” | A | Run `cmd/2` against sample signal | deferred | 2 | GAP-MVP-016 |
| Fixture signal playback | Activity replay | A | Replay through runtime dispatch | deferred | 2 | GAP-MVP-016 |
| Instance config settings | Settings | A | `config :jido_builder_runtime, JidoBuilderRuntime.Jido` | deferred | 2 | GAP-MVP-017 |
| Debug config settings | Settings debug | A | `Jido.Debug` | deferred | 2 | GAP-MVP-017 |
| Observability config | Settings observability | A | `config :jido, :observability` | deferred | 2 | GAP-MVP-017 |
| Redaction settings | Settings privacy | A | `redact_sensitive` | deferred | 2 | GAP-MVP-017 |
| Export template as Elixir | Ejector | B | Builder export/codegen | deferred | 2 | GAP-MVP-018 |
| Export generated action | Ejector | B | Builder export/codegen | deferred | 2 | GAP-MVP-018 |
| Export pod as Elixir | Ejector | B | Builder export/codegen | deferred | 2 | GAP-MVP-018 |
