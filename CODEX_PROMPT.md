You are continuing work on JidoBuilder, a Phoenix LiveView no-code UI for the Jido autonomous agent framework. Read COMMERCIAL_READINESS_PLAN.md at the repo root for the full specification of what needs to be done.

## CURRENT STATE
- Repo: The builder/ directory is an Elixir umbrella app
- 112 tests, 0 failures (run from builder/ directory: `cd builder && mix test`)
- The UI has a dark sidebar app shell with 15 working components (card, badge, button, etc.)
- BUT: Codex broke critical functionality during the UI overhaul — forms don't work, events are silently dropped, agents can't execute real actions

## THE 7 PHASES — EXECUTE IN ORDER

### PHASE 1: Fix @impl true + Restore Working Event Handlers (CRITICAL — DO FIRST)

Without `@impl true`, Phoenix LiveView silently ignores handle_event/handle_info callbacks. This is why buttons and forms appear to do nothing.

**1.1 Add @impl true to ALL missing callbacks in these 8 files:**

| File (under apps/jido_builder_web/lib/jido_builder_web/) | What's missing |
|---|---|
| `live/roster_live.ex` | @impl true before handle_event (line ~11, 4 clauses) AND render (line ~16) |
| `live/agent_live.ex` | @impl true before handle_event("tab") (~L22), handle_info (2 clauses ~L24), render (~L27) |
| `live/dashboard_live.ex` | @impl true before render (~L22) |
| `live/assignments/new_live.ex` | @impl true before handle_event (2 clauses ~L11), render (~L14) |
| `live/execution_live.ex` | @impl true before handle_event (~L13), handle_info (2 clauses ~L15), render (~L21) |
| `live/workflow_builder_live.ex` | @impl true before handle_event (3 clauses ~L15), render (~L19) |
| `live/directives/builder_live.ex` | @impl true before the "preview" handle_event (~L38) |
| `live/skills/index_live.ex` | @impl true before the "select" handle_event (~L36) |

**1.2 Restore the roster hire form in `live/roster_live.ex`:**
The current code opens a modal that says "Use the assignment console to create workers." This is wrong. Replace it with:
- A real `<form id="hire-form" phx-submit="hire_agent">` inside the modal with an agent name `<.input_field>`
- A `handle_event("hire_agent", %{"hire" => %{"name" => name}}, socket)` that calls `JidoBuilderRuntime.Roster.hire(1, String.trim(name), socket.assigns.current_user.email)`
- On success: stream_insert the new agent, close modal, clear error
- On error: show error message
- The `confirm_stop` handler must call `JidoBuilderRuntime.Roster.stop(1, agent_name, actor)` and stream_delete the agent
- Reference the WORKING version pattern from git history: `git show 8025f5f:builder/apps/jido_builder_web/lib/jido_builder_web/live/roster_live.ex`

**1.3 Restore real signal dispatch in `live/assignments/new_live.ex`:**
The current dispatch handler at line 12 returns `%{status: "queued", ms: 1}` — a hardcoded fake. Replace with:
- Extract `signal_type` and `payload` from the form params (`%{"dispatch" => %{"signal_type" => st, "payload" => p}}`)
- Parse payload JSON with `Jason.decode(p)`
- Call `JidoBuilderRuntime.Signals.cast(%{workspace_id: 1, actor: actor}, selected_agent, signal_type, payload)`
- Display real result or error
- Reference the WORKING pattern: `git show 8025f5f:builder/apps/jido_builder_web/lib/jido_builder_web/live/assignments/new_live.ex`

**1.4 Restore workflow create + add step in `live/workflow_builder_live.ex`:**
The current code has no create_workflow or add_step handlers. Add:
- `handle_event("create_workflow", %{"workflow" => %{"name" => name}}, socket)` calling `Workflows.create_workflow(%{workspace_id: 1, name: name, status: "active"}, actor)`
- `handle_event("add_step", %{"step" => %{"name" => name, "kind" => kind}}, socket)` calling `Workflows.create_workflow_step(...)`
- Add the create workflow form and add step form to the left panel of the 3-panel layout
- Reference the WORKING version: `git show 8025f5f:builder/apps/jido_builder_web/lib/jido_builder_web/live/workflow_builder_live.ex`

**VERIFY Phase 1:** `cd builder && mix compile --warnings-as-errors && mix test --seed 0` — 0 warnings, 0 failures.

---

### PHASE 2: Fix BareAgent Signal Routes

**File:** `apps/jido_builder_runtime/lib/jido_builder_runtime/bare_agent.ex`

The current code returns a MAP from signal_routes/1 but Jido expects a LIST of tuples. The Jido SignalRouter at `deps/jido/lib/jido/agent_server/signal_router.ex` calls `normalize_routes` which expects `[{path, target}, ...]`.

**Current (wrong):**
```elixir
@routes %{"ping" => Echo, "increment" => IncrementCounter, "transform" => TransformData, "log" => LogMessage}
def signal_routes(_agent), do: @routes
```

**Fix to:**
```elixir
@routes [
  {"ping", JidoBuilderRuntime.Actions.Echo},
  {"increment", JidoBuilderRuntime.Actions.IncrementCounter},
  {"transform", JidoBuilderRuntime.Actions.TransformData},
  {"log", JidoBuilderRuntime.Actions.LogMessage}
]
@route_map Map.new(@routes)

def signal_routes(_agent), do: @routes
def route_for(type), do: Map.fetch(@route_map, type)
```

If the Direct strategy doesn't pick up agent-level routes (test by hiring an agent and dispatching "ping" — if you still get "No route for signal"), then create a BareStrategy:

```elixir
# apps/jido_builder_runtime/lib/jido_builder_runtime/bare_strategy.ex
defmodule JidoBuilderRuntime.BareStrategy do
  @behaviour Jido.Agent.Strategy

  def cmd(agent, instructions, ctx), do: Jido.Agent.Strategy.Direct.cmd(agent, instructions, ctx)

  def signal_routes(_ctx) do
    [
      {"ping", JidoBuilderRuntime.Actions.Echo},
      {"increment", JidoBuilderRuntime.Actions.IncrementCounter},
      {"transform", JidoBuilderRuntime.Actions.TransformData},
      {"log", JidoBuilderRuntime.Actions.LogMessage}
    ]
  end
end
```

And update BareAgent: `use Jido.Agent, ..., strategy: JidoBuilderRuntime.BareStrategy`

**IMPORTANT:** Read `deps/jido/lib/jido/agent.ex` to understand the exact `use Jido.Agent` options and `signal_routes` callback shape before making changes. Also check `deps/jido/lib/jido/agent/strategy.ex` for the Strategy behaviour.

**Update test:** `apps/jido_builder_runtime/test/bare_agent_routes_test.exs` — change `routes["ping"]` to use list membership: `assert Enum.any?(routes, fn {p, _} -> p == "ping" end)`

**VERIFY Phase 2:** `cd builder && mix test` AND start server, hire an agent, dispatch "ping" — must NOT see "No route for signal" in server logs.

---

### PHASE 3: Dashboard Real KPIs

**File:** `apps/jido_builder_web/lib/jido_builder_web/live/dashboard_live.ex`

Current mount hardcodes `active_workflows: 0, signals_per_hour: 0, recent_errors: 0`. Fix:

```elixir
active_workflows: length(JidoBuilderCore.Workflows.list_workflows(1)),
signals_per_hour: signal_count_last_hour(1),
recent_errors: length(JidoBuilderCore.Observability.list_recent_errors(1, limit: 100))
```

Add a private helper `signal_count_last_hour/1` that queries signal_logs inserted in the last hour:
```elixir
defp signal_count_last_hour(workspace_id) do
  cutoff = DateTime.add(DateTime.utc_now(), -3600, :second)
  import Ecto.Query
  JidoBuilderCore.Repo.aggregate(
    from(s in JidoBuilderCore.Observability.SignalLog,
      where: s.workspace_id == ^workspace_id and s.inserted_at >= ^cutoff),
    :count
  )
end
```

**VERIFY:** `cd builder && mix test`

---

### PHASE 4: Complete JS Hooks

**4.1 `assets/js/hooks/json_tree.js` — Rewrite (~90 LOC)**

Replace the 27-LOC colorized dump with a recursive collapsible tree using `<details><summary>`:
- Each object/array key is a `<details>` element that expands/collapses
- Leaf values are syntax-colored: strings green (#16a34a), numbers blue (#2563eb), booleans purple (#7c3aed), null gray (#a1a1aa)
- "Expand All" / "Collapse All" buttons at top
- Receives JSON via `this.el.dataset.json`, parses and renders on mount/update

**4.2 `assets/js/hooks/execution_timeline.js` — Rewrite (~100 LOC)**

Replace the 16-LOC button row with an SVG horizontal timeline:
- SVG element filling container width, height ~120px
- Time axis at bottom with tick marks
- Events as colored circles (radius 8): cmd=#10b981, signal=#3b82f6, directive=#f59e0b, error=#ef4444
- Horizontal line connecting events
- Hover shows tooltip with event details
- Click pushes `select_event` to LiveView
- `handleEvent("append_event", ...)` adds new events and auto-scrolls right

**4.3 `assets/js/hooks/workflow_dag.js` — Fix (~30 LOC changes)**

The existing 125-LOC hook has a broken zoom. Fix:
- Lines 73-78: Replace `vb[2] += e.deltaY; vb[3] += e.deltaY` with proper scale factor: `const factor = e.deltaY > 0 ? 1.1 : 0.9; scale = Math.max(0.25, Math.min(4, scale * factor))` then update viewBox from scale
- Complete the edge creation: In `onUp`, when `this._linkFrom` is set and mouse is over a different node, push `edge_created` event with `{source: linkFrom.id, target: targetNode.id, workflow_id}`
- Add a dashed SVG line that follows the mouse during link-drag mode

**Register all hooks in `assets/js/app.js`** — they should already be registered, just verify.

**VERIFY:** `cd builder && mix tailwind jido_builder_web && mix esbuild jido_builder_web` — no JS errors.

---

### PHASE 5: Complete CSS + Sidebar Active State

**5.1 Add missing CSS to `assets/css/app.css`:**

```css
.ui-label { display: block; font-size: .875rem; margin-bottom: .25rem; }
.ui-alert { border-radius: .5rem; padding: .75rem 1rem; font-size: .875rem; }
.ui-alert.info { background: #eff6ff; color: #1e40af; border: 1px solid #bfdbfe; }
.ui-alert.danger { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca; }
.ui-alert.success { background: #f0fdf4; color: #166534; border: 1px solid #bbf7d0; }
.ui-alert.warning { background: #fffbeb; color: #92400e; border: 1px solid #fde68a; }
.ui-table { width: 100%; border-collapse: collapse; }
.ui-table td, .ui-table th { padding: .5rem .75rem; border-bottom: 1px solid #e4e4e7; text-align: left; }
.ui-table tr:hover { background: #fafafa; }
.ui-toast { border-left: 4px solid; }
.ui-toast.info { border-color: #3b82f6; }
.ui-toast.success { border-color: #22c55e; }
.ui-toast.danger { border-color: #ef4444; }
.ui-stat { transition: box-shadow .15s; }
.ui-stat:hover { box-shadow: 0 4px 12px rgba(0,0,0,.08); }
```

**5.2 Sidebar active state in `components/layouts/app.html.heex`:**

The sidebar links have no visual indication of the current page. Fix by:
- Getting the current URI. In the layout, use the conn or socket URI. A simple approach: pass `@current_path` from each LiveView's `handle_params` or use an `on_mount` hook.
- For each sidebar link, conditionally apply `bg-zinc-800 text-white rounded` when active vs `text-zinc-400 hover:text-zinc-200` when inactive.

**5.3 Add icons to sidebar nav items:**

Each nav link should have an icon before the label. Use the `<.icon>` component from `JidoBuilderWeb.Icons`:
- OPERATE: Dashboard=`home`, Agents=`users`, Workflows=`play`, Schedules=`clock`
- CONFIGURE: Templates=`cube`, Skills=`puzzle_piece`, Directives=`bolt`, Teams=`users`
- OBSERVE: Execution=`cpu_chip`, Traces=`signal`, Audit=`eye`, Debug=`bug`
- ADMIN: Settings=`cog`, Workspaces=`folder`

Format: `<.icon name="home" class="w-4 h-4 inline mr-2" /> Dashboard`

**VERIFY:** `cd builder && mix tailwind jido_builder_web && mix esbuild jido_builder_web && mix test`

---

### PHASE 6: Polish ~20 Remaining Pages

Apply the UI component library to every LiveView that still uses raw HTML. The components are already imported (via `use JidoBuilderWeb, :live_view` which calls `html_helpers/0` which calls `import JidoBuilderWeb.UI`).

For each page, apply these transformations:
1. Wrap content sections in `<.card><:header>Title</:header> ... </.card>`
2. Replace `<button type="submit" class="...">` with `<.button variant="primary">...</.button>`
3. Replace `<input type="text" name="..." ...>` with `<.input_field name="..." label="..." />`
4. Replace status text like `<span class="text-green-600">running</span>` with `<.badge variant="success">running</.badge>`
5. Add `<.empty_state title="No data" description="..." icon="folder" />` for empty lists
6. Wrap tables in `<.table>` component where appropriate

**Process these files in order (all under `apps/jido_builder_web/lib/jido_builder_web/live/`):**
1. schedules_live.ex
2. teams_live.ex
3. templates/index_live.ex + templates/edit_live.ex
4. hierarchy_live.ex
5. debug_live.ex
6. traces_live.ex
7. audit_live.ex
8. settings_live.ex
9. capability_packs_live.ex + watchers_live.ex
10. orphans_live.ex + pools_live.ex + error_policy_live.ex
11. block_library_live.ex + ejector_live.ex
12. threads_live.ex + memory_live.ex + identity_live.ex
13. onboarding_live.ex + workspaces_live.ex + state_ops_live.ex

IMPORTANT: Keep the existing `mount/3` and `handle_event/3` logic intact. Only change the `render/1` template markup. Do NOT remove any existing `@impl true` annotations or working event handlers.

**VERIFY after each batch:** `cd builder && mix test --seed 0` — 0 failures.

---

### PHASE 7: Integration Testing + Final Verification

**7.1 Update `test/jido_builder_web/live/agent_lifecycle_test.exs`:**
If this test exists, update it. If not, create it:
1. Setup: create workspace + user
2. Visit /roster → hire "lifecycle-bot" via form submit → assert agent appears
3. Visit /assignments/new → select "lifecycle-bot" → dispatch "ping" → assert result shows
4. Visit /roster → stop "lifecycle-bot" → assert removed

**7.2 Update `test/jido_builder_web/live/workflow_lifecycle_test.exs`:**
1. Visit /workflows → create "Test Flow" → assert listed
2. Add step "Step 1" kind "action" → assert in canvas
3. Add step "Step 2" kind "emit" → assert in canvas

**7.3 Final verification commands:**
```bash
cd builder
mix compile --warnings-as-errors    # Must be 0 warnings
mix test --seed 0                    # Must be 0 failures
mix tailwind jido_builder_web       # CSS builds
mix esbuild jido_builder_web        # JS builds
```

**After each phase, commit with:** `git add -A && git commit -m "feat(builder): phase N — description"`

**After ALL phases:** `git push origin main`
