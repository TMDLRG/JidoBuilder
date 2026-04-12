# JidoBuilder Commercial Readiness — DD TDD Plan

## Context

After Codex's UI overhaul PR, the app compiles and 112 tests pass, but critical functionality was broken:
- 7 LiveViews missing `@impl true` on callbacks (events silently ignored at runtime)
- Roster hire form replaced with "use assignment console" redirect text
- Signal dispatch handler returns hardcoded fake result
- BareAgent signal_routes returns a Map (Jido expects a List of tuples)
- 3 JS hooks are stubs (json_tree, execution_timeline are <30 LOC each)
- 4 CSS classes referenced by components but not defined
- Sidebar has no active-state highlighting
- Dashboard KPIs are hardcoded zeros
- ~20 pages still use pre-overhaul raw HTML

The architecture is correct (sidebar, components, panels). The wiring is broken.

---

## Phase 1: Fix @impl true + Restore Working Event Handlers

**This is the prerequisite for everything else. Without @impl true, Phoenix silently drops events.**

### 1.1 Add @impl true to all missing callbacks

| File | Lines needing @impl true before them |
|------|--------------------------------------|
| `live/roster_live.ex` | L11 (handle_events x4), L16 (render) |
| `live/agent_live.ex` | L22 (handle_event), L24 (handle_info x2), L27 (render) |
| `live/dashboard_live.ex` | L22 (render) |
| `live/assignments/new_live.ex` | L11 (handle_events x2), L14 (render) |
| `live/execution_live.ex` | L13 (handle_event), L15 (handle_info x2), L21 (render) |
| `live/workflow_builder_live.ex` | L15 (handle_events x3), L19 (render) |
| `live/directives/builder_live.ex` | L38 (preview handler) |
| `live/skills/index_live.ex` | L36 (select handler) |

### 1.2 Restore roster hire form

**File:** `apps/jido_builder_web/lib/jido_builder_web/live/roster_live.ex`

Replace the modal body (currently "Use the assignment console to create workers") with:
- A real `<form phx-submit="hire_agent">` with agent name input
- `handle_event("hire_agent", %{"name" => name}, socket)` calling `Roster.hire(workspace_id, name, actor)`
- Stream-insert the new agent on success
- Show error on failure
- Restore `confirm_stop` handler calling `Roster.stop/3`

### 1.3 Restore signal dispatch

**File:** `apps/jido_builder_web/lib/jido_builder_web/live/assignments/new_live.ex`

Replace the hardcoded `%{status: "queued", ms: 1}` dispatch handler with:
- Extract `signal_type` and `payload` from form params
- Parse JSON payload with Jason.decode
- Call `JidoBuilderRuntime.Signals.cast/2` to dispatch to the selected agent
- Display real result (success/error) with timing

### 1.4 Restore workflow create/add step

**File:** `apps/jido_builder_web/lib/jido_builder_web/live/workflow_builder_live.ex`

Add handlers:
- `create_workflow` — calls `Workflows.create_workflow/2` with `status: "active"`
- `add_step` — calls `Workflows.create_workflow_step/2`
- `node_moved` — calls `Workflows.update_workflow_step/3` with position
- `edge_created` — calls `Workflows.create_workflow_edge/2`

Add create workflow form + add step form to the left panel (reuse pattern from before Codex).

**Tests:** `mix compile --warnings-as-errors` must show 0 warnings. `mix test` must show 0 failures.

---

## Phase 2: Fix BareAgent Signal Routes

**File:** `apps/jido_builder_runtime/lib/jido_builder_runtime/bare_agent.ex`

### Current (broken):
```elixir
@routes %{"ping" => Echo, "increment" => IncrementCounter, ...}
def signal_routes(_agent), do: @routes  # Returns Map
```

### Fix:
```elixir
@routes [
  {"ping", Echo},
  {"increment", IncrementCounter},
  {"transform", TransformData},
  {"log", LogMessage}
]
@route_map Map.new(@routes)

def signal_routes(_agent), do: @routes  # Returns List of tuples
def route_for(type), do: Map.fetch(@route_map, type)
```

### Alternative (if Direct strategy doesn't pick up agent-level routes):
Create `BareStrategy` module implementing `Jido.Agent.Strategy`:
```elixir
defmodule JidoBuilderRuntime.BareStrategy do
  @behaviour Jido.Agent.Strategy
  def cmd(agent, instructions, ctx), do: Jido.Agent.Strategy.Direct.cmd(agent, instructions, ctx)
  def signal_routes(_ctx), do: [{"ping", Echo}, {"increment", IncrementCounter}, ...]
end
```
Then set `strategy: BareStrategy` in `use Jido.Agent`.

**Test:** Update `bare_agent_routes_test.exs` — assert `is_list(routes)` not `is_map(routes)`. Test that dispatching "ping" to a hired agent returns a result (not "No route").

**Verify:** Hire an agent, dispatch "ping", see real response instead of "No route for signal" error.

---

## Phase 3: Dashboard Real KPIs

**File:** `apps/jido_builder_web/lib/jido_builder_web/live/dashboard_live.ex`

Replace hardcoded zeros in mount:
```elixir
# Current (broken):
active_workflows: 0, signals_per_hour: 0, recent_errors: 0

# Fix:
active_workflows: length(Workflows.list_workflows(1))
signals_per_hour: Observability.signal_count_last_hour(1)  # or count from signal_logs
recent_errors: length(Observability.list_recent_errors(1, limit: 10))
```

If `Observability.signal_count_last_hour/1` doesn't exist, add it as a simple query counting signal_logs rows from the last hour.

---

## Phase 4: Complete JS Hooks

### 4.1 json_tree.js — Rewrite as collapsible tree (~90 LOC)

Replace the 27-LOC colorized dump with recursive `<details><summary>` tree:
- Object keys as expandable nodes
- Syntax coloring: strings green, numbers blue, booleans purple, null gray
- Expand all / collapse all buttons
- Click-to-copy on leaf values

### 4.2 execution_timeline.js — Rewrite as SVG timeline (~100 LOC)

Replace the 16-LOC button row with:
- SVG canvas with horizontal time axis
- Events as colored circles (cmd=emerald, signal=blue, directive=amber, error=red)
- Events positioned by timestamp
- Hover tooltip showing event details
- Click pushes `select_event` to LiveView
- Auto-scroll right as new events arrive via `handleEvent("append_event")`

### 4.3 workflow_dag.js — Fix zoom + edge creation (~30 LOC changes)

- Fix `onWheel` zoom: Replace raw `deltaY` addition with scale factor (`scale *= deltaY > 0 ? 1.1 : 0.9`, clamp 0.25-4.0)
- Complete edge creation in `onUp`: When `linkFrom` is set and mouse is over a different node, push `edge_created` event
- Add visual dashed line during drag-link mode
- Add right-click context menu for delete node/edge

---

## Phase 5: Complete CSS + Sidebar Active State

### 5.1 Missing CSS classes

**File:** `apps/jido_builder_web/assets/css/app.css`

Add:
```css
.ui-label { display: block; font-size: .875rem; margin-bottom: .25rem; }
.ui-alert { border-radius: .5rem; padding: .75rem 1rem; font-size: .875rem; }
.ui-alert.info { background: #eff6ff; color: #1e40af; border: 1px solid #bfdbfe; }
.ui-alert.danger { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca; }
.ui-alert.success { background: #f0fdf4; color: #166534; border: 1px solid #bbf7d0; }
.ui-alert.warning { background: #fffbeb; color: #92400e; border: 1px solid #fde68a; }
.ui-table { width: 100%; border-collapse: collapse; }
.ui-table td, .ui-table th { padding: .5rem .75rem; border-bottom: 1px solid #e4e4e7; }
.ui-table tr:hover { background: #fafafa; }
.ui-toast { border-left: 4px solid; }
.ui-toast.info { border-color: #3b82f6; }
.ui-toast.success { border-color: #22c55e; }
.ui-toast.danger { border-color: #ef4444; }
.ui-stat { transition: box-shadow .15s; }
.ui-stat:hover { box-shadow: 0 4px 12px rgba(0,0,0,.08); }
```

### 5.2 Sidebar active state

**File:** `apps/jido_builder_web/lib/jido_builder_web/components/layouts/app.html.heex`

The sidebar links need conditional highlighting. Pass `@current_path` from the LiveView socket:

In `app.html.heex`, use the request path from the conn/socket to determine active state. For each nav link, apply: `class={if String.starts_with?(@current_uri, "/roster"), do: "bg-zinc-800 text-white rounded px-2 py-1", else: "text-zinc-400 hover:text-white px-2 py-1"}`

This requires adding `@current_uri` to assigns. In the `on_mount` hook or in `app.html.heex`, extract it from `@conn.request_path` or the LiveView socket URI.

### 5.3 Sidebar icons

Add `<.icon>` components next to each nav label:
- Dashboard: `:home`, Agents: `:users`, Workflows: `:play`, Schedules: `:clock`
- Templates: `:cube`, Skills: `:puzzle_piece`, Directives: `:bolt`, Teams: `:users`
- Execution: `:cpu_chip`, Traces: `:signal`, Audit: `:eye`, Debug: `:bug`
- Settings: `:cog`, Workspaces: `:folder`

---

## Phase 6: Polish Remaining ~20 Pages

Apply component library to every LiveView that still uses raw HTML. For each page:
1. Wrap content sections in `<.card>` with `<:header>` slots
2. Replace `<button>` with `<.button>`
3. Replace `<label><input>` with `<.input_field>`
4. Replace plain status text with `<.badge>`
5. Add `<.empty_state>` for zero-data cases
6. Use `<.table>` for list data

Pages (in priority order):
1. schedules_live.ex — table with status badges, create form in card
2. teams_live.ex — card grid with create form
3. templates/index_live.ex — table with edit links
4. templates/edit_live.ex — form in card
5. hierarchy_live.ex — tree in card, add node form
6. debug_live.ex — toggle card, error/trace tables
7. traces_live.ex — filter + list in card
8. audit_live.ex — table with timestamps
9. settings_live.ex — forms in cards
10. capability_packs_live.ex — card grid
11. watchers_live.ex — card grid
12. orphans_live.ex — table with adopt buttons
13. pools_live.ex — table with edit form
14. error_policy_live.ex — form with radio buttons
15. blocks/block_library_live.ex — card grid
16. ejector_live.ex — form + preview card
17. threads_live.ex — form + list
18. memory_live.ex — form + list
19. identity_live.ex — form + list
20. onboarding_live.ex — step wizard in cards
21. workspaces_live.ex — form + list cards

---

## Phase 7: Integration Testing + Final Verification

### 7.1 End-to-end agent lifecycle test
**File:** `test/jido_builder_web/live/agent_lifecycle_test.exs`

1. Visit roster → hire agent "test-bot" → verify appears in list
2. Visit assignments → select "test-bot" → dispatch "ping" signal → verify result shows
3. Visit agent detail → verify state tab shows agent state
4. Visit execution → verify timeline has events
5. Visit roster → stop "test-bot" → verify removed from list
6. Visit dashboard → verify running agents KPI decremented

### 7.2 Workflow lifecycle test
**File:** `test/jido_builder_web/live/workflow_lifecycle_test.exs`

1. Visit workflows → create "Test Pipeline"
2. Add 3 steps (action, transform, emit)
3. Verify steps appear in canvas
4. Verify DB has workflow + steps

### 7.3 Final verification
```bash
mix compile --warnings-as-errors  # 0 warnings
mix test                          # 0 failures, 120+ tests
mix credo --strict                # 0 issues (or documented waivers)
```

Start server, navigate every sidebar link — no crashes. Hire 3 agents, dispatch signals, see results. Build workflow with steps. Check execution monitor for events.

---

## Execution Order

```
Phase 1 (@impl + forms)  ← FIRST, everything depends on this
  ↓
Phase 2 (BareAgent fix)  ← Makes agents actually work
  ↓
Phase 3 (Dashboard KPIs) ← Independent, quick win
  ↓
Phase 4 (JS hooks)       ← Can parallel with Phase 5
Phase 5 (CSS + sidebar)  ← Can parallel with Phase 4
  ↓
Phase 6 (Polish pages)   ← Depends on Phase 5 CSS
  ↓
Phase 7 (Testing)        ← Final
```

## Critical Files

| File | Change | Phase |
|------|--------|-------|
| 8 LiveView files | Add @impl true | 1 |
| `live/roster_live.ex` | Restore hire form + handlers | 1 |
| `live/assignments/new_live.ex` | Restore real dispatch | 1 |
| `live/workflow_builder_live.ex` | Restore create/step/edge | 1 |
| `runtime/bare_agent.ex` | Fix signal_routes return type | 2 |
| `live/dashboard_live.ex` | Real KPI queries | 3 |
| `js/hooks/json_tree.js` | Collapsible tree rewrite | 4 |
| `js/hooks/execution_timeline.js` | SVG timeline rewrite | 4 |
| `js/hooks/workflow_dag.js` | Fix zoom + edge creation | 4 |
| `assets/css/app.css` | Add 4 missing component styles | 5 |
| `layouts/app.html.heex` | Active state + icons | 5 |
| ~20 LiveView files | Component library polish | 6 |
