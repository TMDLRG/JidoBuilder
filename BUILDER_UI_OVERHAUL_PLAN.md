# JidoBuilder Complete UI Overhaul + Runtime Wiring — DDTDD Plan

## Context

**Problem:** The JidoBuilder UI is a developer wireframe — raw HTML, no design system, no icons, fake workflow visualization, and agents can't execute real work because BareAgent has zero signal routes. The product must rival commercial agent builder UIs (CrewAI, n8n, Dify) to serve Organic Operators building simple to complex Jido solutions.

**Current State:** 109 tests/0 failures, 34 routes, 5-app umbrella. Agents hire/stop works. Signals dispatch but produce "No route for signal" because BareAgent has no routes configured. WorkflowDag renders nodes as plain text divs. No component library (1 component: `page_header`). No sidebar, no icons, no cards, no modals. Tailwind v4 works but zero custom design tokens.

**Outcome:** A beautiful, intuitive, commercial-grade agent builder with: dark sidebar app shell, professional component library, real SVG drag-and-drop workflow editor, agents that execute real actions with visible state changes, real-time execution monitoring, and every page polished to production quality.

---

## Phase 1: Design System + App Shell (Foundation)

### 1.1 Design Tokens
**File:** `builder/apps/jido_builder_web/assets/css/app.css`
- Add `@theme` block: brand colors (emerald), sidebar colors (zinc-900), surface/raised/overlay, semantic colors (success/danger/warning/info), shadows, radii, font-mono
- Add custom base styles for sidebar transitions, scrollbar styling

### 1.2 Icon System
**File:** `builder/apps/jido_builder_web/lib/jido_builder_web/components/icons.ex` (NEW)
- ~25 inline SVG icon components via `icon/1` function component (`:home`, `:users`, `:play`, `:cog`, `:bolt`, `:clock`, `:folder`, `:bug`, `:search`, `:chart_bar`, `:eye`, `:plus`, `:x`, `:chevron_left`, `:chevron_right`, `:exclamation_triangle`, `:check_circle`, `:arrow_path`, `:beaker`, `:cube`, `:puzzle_piece`, `:signal`, `:cpu_chip`, `:command_line`, `:trash`)
- Import in `html_helpers/0` in `jido_builder_web.ex`

### 1.3 Component Library
**File:** `builder/apps/jido_builder_web/lib/jido_builder_web/components/ui.ex` (NEW)
Components with full `attr`/`slot` declarations:

| Component | Key attrs | Purpose |
|-----------|-----------|---------|
| `button/1` | variant (primary/secondary/danger/ghost), size, disabled | All buttons |
| `card/1` | padding | Content containers with header/body/footer slots |
| `modal/1` | id, show, on_cancel | Dialogs (hire agent, stop confirm, config) |
| `badge/1` | variant (success/danger/warning/info/neutral) | Status indicators |
| `input_field/1` | field, type, label, help_text, errors | Form fields with labels/validation |
| `table/1` | id, rows | Data tables with col slot |
| `alert/1` | variant, dismissable | Notifications |
| `stat_card/1` | label, value, icon, variant | Dashboard KPIs |
| `page_header/1` | (existing) | Extended with `actions` slot |
| `breadcrumb/1` | items | Navigation breadcrumbs |
| `empty_state/1` | icon, title, description | Empty data states |
| `tabs/1` | active_tab, items | Tab navigation |
| `toast/1` | variant, title, message | Non-blocking notifications |
| `spinner/1` | size | Loading indicator |
| `skeleton/1` | variant | Loading placeholder |

Import in `html_helpers/0` in `jido_builder_web.ex` (line 60, alongside CoreComponents).

### 1.4 App Shell (3-Panel Layout)
**File:** `builder/apps/jido_builder_web/lib/jido_builder_web/components/layouts/app.html.heex` (REWRITE)

Replace flat horizontal nav with:
- **Left:** Dark sidebar (bg-zinc-900, w-64, collapsible) with logo, icon+label nav items, collapse toggle
- **Top:** White header bar (h-14) with sidebar toggle, breadcrumbs, Cmd+K search trigger, user email
- **Center:** Scrollable main content area (bg-zinc-100, p-6)

Sidebar nav groups:
- OPERATE: Dashboard, Agents, Workflows, Schedules
- CONFIGURE: Templates, Skills, Directives, Teams
- OBSERVE: Execution, Traces, Audit, Debug
- ADMIN: Settings, Workspaces

**File:** `builder/apps/jido_builder_web/assets/js/app.js` — Add `Sidebar` hook for collapse/expand (localStorage persistence), Cmd+K shortcut

### 1.5 Tests
- Update `app_shell_test.exs` — assert sidebar, header, nav structure
- New `test/jido_builder_web/components/ui_test.exs` — component rendering tests
- All 109 existing tests must pass (update selectors where old nav HTML is asserted)

---

## Phase 2: Runtime Wiring (Agents Actually Work)

### 2.1 Demo Actions
**Files:** `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/actions/` (NEW directory)
- `echo.ex` — returns input unchanged (`use Jido.Action`, `run/2` returns `{:ok, %{echo: message}}`)
- `increment_counter.ex` — increments agent counter state
- `transform_data.ex` — applies uppercase/reverse/sort operations on input
- `log_message.ex` — appends message to agent log list

### 2.2 BareAgent with Real Routes
**File:** `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/bare_agent.ex` (MODIFY)
- Add schema fields: `counter: [type: :integer, default: 0]`, `last_result: [type: :map, default: %{}]`, `log: [type: {:list, :map}, default: []]`
- Wire signal routes so "ping"→Echo, "increment"→IncrementCounter, "transform"→TransformData, "log"→LogMessage

Key constraint: Must work within Jido's `use Jido.Agent` macro system. The exact routing mechanism depends on how `Jido.Agent.Strategy` and `signal_routes/1` work — needs investigation of `deps/jido/lib/jido/agent.ex` to determine the correct callback shape.

### 2.3 State Change PubSub Bridge
**File:** `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/event_bus.ex` (MODIFY)
- Add `agent_state_topic/2` function

**File:** `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/telemetry_bridge.ex` (MODIFY)
- After `[:jido, :agent, :cmd, :stop]` telemetry events, publish `{:agent_state_changed, %{agent_id, state, timestamp}}` to the agent state topic

### 2.4 Agent State Persistence
**File:** `builder/apps/jido_builder_runtime/lib/jido_builder_runtime/roster.ex` (MODIFY)
- Add `update_agent_state/3` — writes state snapshot to `agent_instances.state` column

### 2.5 Tests
- New `test/actions_test.exs` — each action's `run/2` returns expected output
- New `test/bare_agent_routes_test.exs` — BareAgent routes signals correctly (no more "No route" errors)
- New `test/state_pubsub_test.exs` — state change messages flow through PubSub

---

## Phase 3: Core Page Redesigns

### 3.1 Dashboard
**File:** `builder/apps/jido_builder_web/lib/jido_builder_web/live/dashboard_live.ex` (REWRITE)
- 4 KPI `stat_card` components in grid (Running Agents, Active Workflows, Signals/hr, Recent Errors)
- Activity feed in a `card` with timeline-style rows (icon + action + actor + relative time)
- Quick Actions card (Hire Agent, Create Workflow, View Traces)
- Recent Errors card with red badges

### 3.2 Agent Roster
**File:** `builder/apps/jido_builder_web/lib/jido_builder_web/live/roster_live.ex` (REWRITE)
- Card grid view of agents (each card: name, status badge, uptime, template, View/Stop buttons)
- Hire modal (triggered from page_header actions button)
- Stop confirmation modal
- Empty state with illustration when no agents

### 3.3 Agent Detail
**File:** `builder/apps/jido_builder_web/lib/jido_builder_web/live/agent_live.ex` (REWRITE)
- Tabbed interface: Overview | State Inspector | Signal History | Action Log
- Overview: metadata cards, inline signal dispatch form, recent events
- State Inspector: JSON tree viewer (new `JsonTree` JS hook — collapsible, syntax-colored)
- Signal History: table of signals with timestamp, type, direction, status
- Action Log: table of executed actions with duration and result
- Subscribe to `agent_state_topic` for real-time state updates

**File:** `builder/apps/jido_builder_web/assets/js/hooks/json_tree.js` (NEW)
- Collapsible JSON tree with syntax coloring (string=green, number=blue, boolean=purple, null=gray)
- Copy-to-clipboard on leaf values, expand/collapse all

### 3.4 Signal Dispatch
**File:** `builder/apps/jido_builder_web/lib/jido_builder_web/live/assignments/new_live.ex` (REWRITE)
- Agent selector as card grid (not plain select dropdown)
- Signal type with autocomplete from known routes
- JSON payload editor with validation
- Result panel with expandable details, status badge, timing

### 3.5 Tests
- Update existing roster/agent/dashboard tests for new selectors
- New `agent_detail_tabs_test.exs` — tab switching, state inspector hook present

---

## Phase 4: Workflow Builder (SVG Visual Editor)

### 4.1 Data Model
**Migration:** Add `workflow_edges` table (workflow_id, source_step_id, target_step_id, label, condition)
**Schema:** `builder/apps/jido_builder_core/lib/jido_builder_core/workflows/workflow_edge.ex` (NEW)
**Context:** Add edge CRUD to `builder/apps/jido_builder_core/lib/jido_builder_core/workflows.ex`

### 4.2 SVG Editor Hook
**File:** `builder/apps/jido_builder_web/assets/js/hooks/workflow_dag.js` (COMPLETE REWRITE ~400 LOC)

SVG-based canvas with:
- **Nodes** as `<g>` groups: colored `<rect>` (by kind) + `<text>` label + input/output ports (small circles)
- **Edges** as cubic bezier `<path>` elements between ports
- **Drag nodes** via mousedown/mousemove/mouseup
- **Draw edges** by dragging from output port to input port
- **Pan** canvas via mouse drag on background
- **Zoom** via mouse wheel (transform scale)
- **Select node** by clicking (highlights, pushes event to LV for config panel)
- **Node types** color-coded: action=emerald, emit=blue, condition=amber, transform=purple
- **Toolbar** at top: Add Node dropdown, Zoom In/Out, Fit to Screen, Save

Events to LiveView: `node_moved`, `node_selected`, `edge_created`, `edge_removed`, `save_workflow`
Events from LiveView: `init_graph`, `highlight_step` (for execution viz)

### 4.3 Builder LiveView
**File:** `builder/apps/jido_builder_web/lib/jido_builder_web/live/workflow_builder_live.ex` (REWRITE)

Three-panel layout:
- **Left (narrow):** Workflow list + create form, node palette
- **Center (wide):** SVG canvas with WorkflowDag hook
- **Right (conditional):** Node config side panel (name, kind, config JSON, delete)

### 4.4 Tests
- Update `workflow_dag_test.exs` — SVG container, edge events
- New `workflows_edges_test.exs` — edge CRUD, cascade deletes

---

## Phase 5: Execution Monitor (Real-Time)

### 5.1 Execution Monitor Page
**File:** `builder/apps/jido_builder_web/lib/jido_builder_web/live/execution_live.ex` (NEW)
**Routes:** `/execution` and `/execution/:agent_id`

- Timeline visualization of agent execution events
- Agent filter dropdown
- Event detail panel (JSON tree view on click)
- Auto-scroll as new events arrive
- Subscribe to workspace + agent PubSub topics

### 5.2 Timeline Hook
**File:** `builder/apps/jido_builder_web/assets/js/hooks/execution_timeline.js` (NEW)
- Horizontal timeline with color-coded events
- Hover tooltip, click for detail, auto-scroll

### 5.3 Workflow Execution Visualization
Extend `workflow_dag.js`: `highlight_step` events pulse/glow active steps, green/red for success/failure

### 5.4 Tests
- New `execution_monitor_test.exs`

---

## Phase 6: Polish All Remaining Pages

Apply component library to ALL 25+ remaining LiveView pages:
1. Schedules — table with badges, create modal
2. Teams/Pods — card grid, create modal
3. Templates — table with status badges
4. Skills — searchable card grid + detail panel
5. Directives — structured form in card
6. Settings — tabbed layout, redacted secrets
7. Traces — timeline + detail
8. Audit — filterable table
9. Debug — toggle card, error/trace panels
10. All remaining: Hierarchy, Blocks, Ejector, Threads, Memory, Identity, Onboarding, etc.

Toast notifications for all CRUD operations.

---

## Phase 7: Testing + Verification

### 7.1 Update All Existing Tests
- Sidebar/header selectors, modal-wrapped forms, component selectors

### 7.2 New Integration Tests
- `agent_lifecycle_test.exs` — hire → dispatch → state change → execution → stop
- `workflow_lifecycle_test.exs` — create → steps → edges → save → verify

### 7.3 Verification Checklist
1. `mix test` — 140+ tests, 0 failures
2. `mix compile --warnings-as-errors` — no warnings
3. Navigate every sidebar link — no crashes
4. Hire 3 agents, dispatch signals, see state changes in Agent Detail
5. Build workflow with nodes + edges, save, reload
6. Open Execution Monitor, see real-time events

---

## Implementation Order

```
Phase 1 (Foundation)     ← No deps, do first
  ↓
Phase 2 (Runtime)        ← Independent, can parallel with Phase 1
  ↓
Phase 3 (Core Pages)     ← Needs Phase 1 + Phase 2
  ↓
Phase 4 (Workflow)       ← Needs Phase 1
  ↓
Phase 5 (Execution)      ← Needs Phase 2 + Phase 1
  ↓
Phase 6 (Polish)         ← Needs Phase 1
  ↓
Phase 7 (Testing)        ← Needs all phases
```

---

## Critical Files

| File | Action | Phase |
|------|--------|-------|
| `assets/css/app.css` | Add @theme tokens | 1 |
| `components/icons.ex` | NEW — 25 SVG icons | 1 |
| `components/ui.ex` | NEW — 15+ components | 1 |
| `jido_builder_web.ex` | Add imports | 1 |
| `layouts/app.html.heex` | REWRITE — sidebar shell | 1 |
| `runtime/actions/*.ex` | NEW — 4 demo actions | 2 |
| `runtime/bare_agent.ex` | MODIFY — schema + routes | 2 |
| `runtime/event_bus.ex` | MODIFY — state topic | 2 |
| `runtime/telemetry_bridge.ex` | MODIFY — state PubSub | 2 |
| `live/dashboard_live.ex` | REWRITE — KPIs + activity | 3 |
| `live/roster_live.ex` | REWRITE — cards + modals | 3 |
| `live/agent_live.ex` | REWRITE — tabs + state | 3 |
| `js/hooks/json_tree.js` | NEW — JSON viewer | 3 |
| `js/hooks/workflow_dag.js` | REWRITE — SVG editor | 4 |
| `live/workflow_builder_live.ex` | REWRITE — 3-panel | 4 |
| `core/workflows/workflow_edge.ex` | NEW — edge schema | 4 |
| `live/execution_live.ex` | NEW — monitor | 5 |
| `js/hooks/execution_timeline.js` | NEW — timeline | 5 |
| All 25+ LiveView files | Component redesign | 6 |
