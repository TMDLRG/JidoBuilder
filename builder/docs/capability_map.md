# Builder Capability Map

Status legend: `done` = implemented in this branch, `planned` = mapped and scoped, `deferred` = explicitly postponed.

| Capability Group | UI Surface | Path | Status | Confidence | Notes |
|---|---|---:|---|---:|---|
| Agents & lifecycle (`start/stop/list/count/whereis/debug/recent/hibernate/thaw`) | Roster, Agent Detail, Vault, Settings | A | planned | 3 | Runtime adapter in `jido_builder_runtime` will wrap `Jido` top-level APIs. |
| AgentServer APIs (`call/cast/state/recent_events/set_debug`) | Assignment Composer, Agent Detail | A | planned | 3 | Routed through runtime service boundary. |
| Discovery catalog (`list_*`, `get_*`, `catalog`, `refresh`) | Skills/Agents/Plugins/Sensors catalogs | A/B | planned | 4 | B path calls `refresh/0` after codegen compile. |
| Signals (`Jido.Signal.new!`) | Assignment Composer | A | planned | 4 | Compose CloudEvents envelope from forms. |
| Directives (Emit/Error/Spawn/SpawnAgent/AdoptChild/StopChild/Schedule/RunInstruction/Stop/Cron/CronCancel) | Directive Builder | A | planned | 4 | Data-driven emitter action in runtime app. |
| State operations (`SetState/ReplaceState/DeleteKeys/SetPath/DeletePath`) | State Ops editor | A | planned | 4 | Runtime state-op action applies typed op rows. |
| Built-in actions (Control/Lifecycle/Scheduling/Status) | Skills catalog & Assignment UI | A | planned | 3 | Allow-listed dispatch through Discovery slug lookup. |
| Strategies (Direct/FSM/Custom) | Work Styles editor | A+B | planned | 3 | Direct/FSM data-driven first; custom via codegen blocks. |
| Pods (`Topology/get/ensure_node/mutate/actions`) | Teams topology screens | A | planned | 3 | DynamicPod reads DB topology and executes pod actions. |
| Plugins (`Plugin` behavior + config routes/schedules/lifecycle) | Capability Packs | A+B | planned | 3 | Parametric plugin via A, custom hooks via B. |
| Sensors (`Sensor` behavior + heartbeat/bus/custom) | Watchers screens | A+B | planned | 3 | Sensor host manages lifecycle + custom sensor generation. |
| Storage (`ETS/File/Redis`, `Persist`, `InstanceManager`) | Settings + Vault | A | planned | 3 | MVP default ETS; file/redis selectable. |
| Threading (`Thread`, stores, plugin) | Threads screens | A | planned | 2 | Persist/read thread stores via core contexts. |
| Memory (`Memory`, `Space`, plugin) | Memory screens | A | planned | 2 | Template-configured memory spaces. |
| Identity (`Identity`, `Profile`, plugin) | Identity screens | A | planned | 2 | Template-configured identity profiles. |
| Observability (`Observe`, tracing, telemetry events) | Activity, Traces, Metrics | A | planned | 3 | Telemetry bridge -> PubSub streams into LV. |
| Scheduling (`Scheduler`, jobs, cron/timeout directives) | Schedules screens | A | planned | 3 | Declarative + dynamic schedule workflows. |
| Await coordination (`completion/child/all/any/alive/cancel/get_*`) | Playbooks, Hierarchy | A | planned | 3 | Runtime orchestration helpers. |
| Worker pools (`Agent.WorkerPool`) | Pools settings | A | planned | 2 | Pool config stored per template/partition. |
| Igniter templates/helpers reuse | Codegen block compiler internals | B | planned | 2 | Reuse safe templates where applicable. |
| Parent binding (`Jido.parent_binding/2,3`) | Hierarchy view | A | planned | 3 | Visual parent-child graph lookup. |

## Phase execution status

- **Phase 0/1 (bootstrap + mapping):** in-progress.
- **Completed in this branch:** umbrella scaffolding and app boundaries under `builder/apps/*`.
- **Next:** wire Phoenix/Ecto runtime stack, then implement Tier A screens.
