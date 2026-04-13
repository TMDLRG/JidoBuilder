defmodule JidoBuilderWeb.GuideLive do
  @moduledoc """
  Comprehensive in-app User Guide & Manual.

  A single-page scrollable document with sticky table-of-contents sidebar,
  covering every feature of the JidoBuilder management console. Content is
  factual and verified against the actual codebase.
  """
  use JidoBuilderWeb, :live_view

  @sections [
    %{
      id: "welcome",
      title: "Welcome",
      icon: "home",
      children: [
        %{id: "what-is-jido-builder", title: "What is Jido Builder?"},
        %{id: "architecture", title: "Architecture"},
        %{id: "key-concepts", title: "Key Concepts"}
      ]
    },
    %{
      id: "getting-started",
      title: "Getting Started",
      icon: "play",
      children: [
        %{id: "first-login", title: "First Login"},
        %{id: "create-workspace", title: "Create a Workspace"},
        %{id: "first-agent", title: "Your First Agent"},
        %{id: "send-signal", title: "Send Your First Signal"}
      ]
    },
    %{
      id: "operate",
      title: "Operate",
      icon: "chart_bar",
      children: [
        %{id: "dashboard", title: "Dashboard"},
        %{id: "agents", title: "Agents (Roster)"},
        %{id: "workflows", title: "Workflows"},
        %{id: "schedules", title: "Schedules"},
        %{id: "dispatch", title: "Dispatch Signal"}
      ]
    },
    %{
      id: "configure",
      title: "Configure",
      icon: "cog",
      children: [
        %{id: "templates", title: "Templates"},
        %{id: "skills", title: "Skills"},
        %{id: "directives", title: "Directives"},
        %{id: "teams", title: "Teams (Pods)"}
      ]
    },
    %{
      id: "observe",
      title: "Observe",
      icon: "eye",
      children: [
        %{id: "execution", title: "Execution Monitor"},
        %{id: "traces", title: "Traces"},
        %{id: "audit", title: "Audit Log"},
        %{id: "debug", title: "Debug Console"}
      ]
    },
    %{
      id: "admin",
      title: "Admin",
      icon: "shield",
      children: [
        %{id: "settings", title: "Settings"},
        %{id: "workspaces", title: "Workspaces"}
      ]
    },
    %{
      id: "advanced",
      title: "Advanced",
      icon: "cpu_chip",
      children: [
        %{id: "state-ops", title: "State Ops"},
        %{id: "hierarchy", title: "Hierarchy"},
        %{id: "vault", title: "Vault"},
        %{id: "pools", title: "Pools"},
        %{id: "blocks", title: "Block Library"},
        %{id: "identity", title: "Identity Profiles"},
        %{id: "threads", title: "Threads"},
        %{id: "memory-spaces", title: "Memory Spaces"}
      ]
    },
    %{
      id: "reference",
      title: "Reference",
      icon: "book_open",
      children: [
        %{id: "glossary-ref", title: "Glossary"},
        %{id: "keyboard-shortcuts", title: "Keyboard Shortcuts"},
        %{id: "signal-types", title: "Built-in Signal Types"}
      ]
    },
    %{
      id: "active-inference",
      title: "Active Inference",
      icon: "chart_bar",
      children: [
        %{id: "what-is-active-inference", title: "What is Active Inference?"},
        %{id: "creating-generative-model", title: "Creating a Generative Model"},
        %{id: "understanding-belief-states", title: "Understanding Belief States"},
        %{id: "building-ai-agent", title: "Building an Active Inference Agent"}
      ]
    },
    %{
      id: "llm-agents",
      title: "LLM Agents",
      icon: "cpu_chip",
      children: [
        %{id: "configuring-llm-provider", title: "Configuring an LLM Provider"},
        %{id: "creating-llm-agent", title: "Creating an LLM Agent"},
        %{id: "tool-use-conversations", title: "Tool Use and Conversations"},
        %{id: "memory-augmented-agents", title: "Memory-Augmented Agents"}
      ]
    },
    %{
      id: "agent-factory",
      title: "Agent Factory",
      icon: "cube",
      children: [
        %{id: "composing-templates", title: "Composing Templates"},
        %{id: "cloning-customizing", title: "Cloning and Customizing"},
        %{id: "deploying-agent-teams", title: "Deploying Agent Teams"}
      ]
    },
    %{
      id: "notebook-guide",
      title: "Notebook",
      icon: "document",
      children: [
        %{id: "writing-code-cells", title: "Writing Code Cells"},
        %{id: "loading-editing-agents", title: "Loading and Editing Agents"},
        %{id: "testing-exporting", title: "Testing and Exporting"}
      ]
    },
    %{
      id: "solutions-guide",
      title: "Solutions",
      icon: "archive_box",
      children: [
        %{id: "deploying-business-solution", title: "Deploying a Business Solution"},
        %{id: "customizing-solutions", title: "Customizing Solutions"}
      ]
    },
    %{
      id: "template-library-guide",
      title: "Template Library",
      icon: "puzzle_piece",
      children: [
        %{id: "browsing-installing-templates", title: "Browsing and Installing Templates"},
        %{id: "creating-shareable-templates", title: "Creating Shareable Templates"}
      ]
    },
    %{
      id: "about",
      title: "About",
      icon: "user",
      children: [
        %{id: "about-author", title: "About the Author"},
        %{id: "about-method", title: "The ORCHESTRATE Method"},
        %{id: "about-projects", title: "Other Projects"},
        %{id: "about-build", title: "How This Was Built"}
      ]
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "User Guide", sections: @sections, active_section: "welcome")}
  end

  @impl true
  def handle_event("nav_to", %{"section" => section}, socket) do
    {:noreply, assign(socket, active_section: section)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex gap-6 -m-6">
      <%!-- Table of Contents sidebar --%>
      <nav class="w-56 shrink-0 bg-white border-r border-zinc-200 p-4 overflow-y-auto sticky top-0 h-screen text-sm">
        <h2 class="font-semibold text-zinc-900 mb-4 text-base">User Guide</h2>
        <ul class="space-y-3">
          <li :for={section <- @sections}>
            <a href={"##{section.id}"} class="flex items-center gap-2 font-medium text-zinc-700 hover:text-emerald-600 transition-colors">
              <.icon name={section.icon} class="w-3.5 h-3.5 text-zinc-400" />
              {section.title}
            </a>
            <ul :if={section[:children]} class="ml-5 mt-1 space-y-0.5">
              <li :for={child <- section.children}>
                <a href={"##{child.id}"} class="text-xs text-zinc-500 hover:text-emerald-600 transition-colors block py-0.5">
                  {child.title}
                </a>
              </li>
            </ul>
          </li>
        </ul>
      </nav>

      <%!-- Guide content --%>
      <article class="flex-1 max-w-3xl py-6 pr-6 space-y-12">

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- WELCOME --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="welcome" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">Welcome</h2>

          <div id="what-is-jido-builder" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">What is Jido Builder?</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              Jido Builder is a web-based management console for the
              <strong>Jido agent framework</strong>. It provides a visual interface to
              create, configure, deploy, and monitor autonomous agents built on the
              Jido Elixir library. Through Builder you can design agent templates,
              compose workflows, dispatch signals, and observe execution in real time
              &mdash; all without writing code.
            </p>
            <div class="bg-emerald-50 border border-emerald-200 rounded-lg p-4 text-sm text-emerald-800">
              <strong>Built for operators.</strong> Jido Builder bridges the gap between
              the Jido SDK (for developers) and day-to-day agent operations. Developers
              define Actions; operators use Builder to assemble and run them.
            </div>
          </div>

          <div id="architecture" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Architecture</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The application is composed of three OTP applications running in a single BEAM node:
            </p>
            <dl class="grid grid-cols-3 gap-4 text-sm">
              <div class="bg-zinc-50 rounded-lg p-3 border">
                <dt class="font-semibold text-zinc-800">Core</dt>
                <dd class="text-xs text-zinc-500 mt-1">
                  Ecto schemas, business logic, database persistence. Manages templates,
                  workflows, audit events, and signal logs.
                </dd>
              </div>
              <div class="bg-zinc-50 rounded-lg p-3 border">
                <dt class="font-semibold text-zinc-800">Runtime</dt>
                <dd class="text-xs text-zinc-500 mt-1">
                  Agent supervision via the Jido library. The Roster hires/stops agents,
                  Hiring manages process lifecycles, Signals dispatches messages.
                </dd>
              </div>
              <div class="bg-zinc-50 rounded-lg p-3 border">
                <dt class="font-semibold text-zinc-800">Web</dt>
                <dd class="text-xs text-zinc-500 mt-1">
                  Phoenix LiveView UI with real-time PubSub updates. Every page streams
                  live data from the Runtime layer.
                </dd>
              </div>
            </dl>
          </div>

          <div id="key-concepts" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Key Concepts</h3>
            <dl class="space-y-2 text-sm">
              <div class="flex gap-3">
                <dt class="font-semibold text-zinc-700 w-24 shrink-0">Agent</dt>
                <dd class="text-zinc-600">A supervised Elixir process backed by <code class="bg-zinc-100 px-1 rounded text-xs">Jido.Agent</code>. Each agent has its own state, signal routes, and lifecycle.</dd>
              </div>
              <div class="flex gap-3">
                <dt class="font-semibold text-zinc-700 w-24 shrink-0">Signal</dt>
                <dd class="text-zinc-600">A CloudEvent-compatible message dispatched to an agent. Signals trigger actions via route matching (e.g., <code class="bg-zinc-100 px-1 rounded text-xs">ping &rarr; Echo</code>).</dd>
              </div>
              <div class="flex gap-3">
                <dt class="font-semibold text-zinc-700 w-24 shrink-0">Action</dt>
                <dd class="text-zinc-600">A pure function that receives params, performs work, and returns directives or state operations.</dd>
              </div>
              <div class="flex gap-3">
                <dt class="font-semibold text-zinc-700 w-24 shrink-0">Template</dt>
                <dd class="text-zinc-600">A reusable agent blueprint defining routes, plugins, sensors, and initial state fields.</dd>
              </div>
              <div class="flex gap-3">
                <dt class="font-semibold text-zinc-700 w-24 shrink-0">Workflow</dt>
                <dd class="text-zinc-600">A directed graph of steps (actions, emits, conditions, transforms) connecting multiple agents.</dd>
              </div>
              <div class="flex gap-3">
                <dt class="font-semibold text-zinc-700 w-24 shrink-0">Directive</dt>
                <dd class="text-zinc-600">An instruction returned by an Action telling the runtime what to do next (emit, spawn, schedule, stop, cron).</dd>
              </div>
            </dl>
          </div>
        </section>

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- GETTING STARTED --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="getting-started" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">Getting Started</h2>

          <div id="first-login" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">First Login</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              Navigate to the Builder URL in your browser. You will be presented with a
              login screen. Enter your email and password to authenticate. The default
              development credentials are configured in your environment seeds.
            </p>
          </div>

          <div id="create-workspace" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Create a Workspace</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              Workspaces partition all data in Builder &mdash; agents, templates, workflows,
              and audit events are scoped to a workspace. Navigate to
              <strong>Admin &rarr; Workspaces</strong> to create your first workspace with
              a name and slug. The default workspace (ID 1) is created automatically.
            </p>
            <ol class="list-decimal list-inside text-sm text-zinc-600 space-y-1">
              <li>Click <strong>Workspaces</strong> in the Admin sidebar section</li>
              <li>Enter a name (e.g., "Production") and slug (e.g., "prod")</li>
              <li>Click <strong>Create</strong> to provision the workspace</li>
            </ol>
          </div>

          <div id="first-agent" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Your First Agent</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              Agents are hired from the <strong>Roster</strong> page. Each agent is a live
              Elixir process managed by the Jido supervision tree.
            </p>
            <ol class="list-decimal list-inside text-sm text-zinc-600 space-y-1">
              <li>Navigate to <strong>Operate &rarr; Agents</strong></li>
              <li>Click the green <strong>Hire</strong> button in the top-right</li>
              <li>Enter a unique agent name (e.g., "alpha") and click <strong>Hire</strong></li>
              <li>The agent card appears immediately with a "running" badge</li>
              <li>Click <strong>View</strong> to inspect agent details and state</li>
            </ol>
            <div class="bg-amber-50 border border-amber-200 rounded-lg p-3 text-sm text-amber-800">
              <strong>Note:</strong> Agent processes live in memory. If the server restarts,
              agents must be re-hired. Use the <strong>Stop</strong> button to cleanly
              terminate an agent and remove its database record.
            </div>
          </div>

          <div id="send-signal" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Send Your First Signal</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              Signals are dispatched to agents via the <strong>Dispatch Signal</strong> page.
              The BareAgent template supports four built-in signal types:
            </p>
            <ul class="text-sm text-zinc-600 space-y-1">
              <li><code class="bg-zinc-100 px-1.5 py-0.5 rounded text-xs font-mono">ping</code> &rarr; Echo &mdash; echoes the payload back</li>
              <li><code class="bg-zinc-100 px-1.5 py-0.5 rounded text-xs font-mono">transform</code> &rarr; TransformData &mdash; transforms the payload</li>
              <li><code class="bg-zinc-100 px-1.5 py-0.5 rounded text-xs font-mono">increment</code> &rarr; IncrementCounter &mdash; increments a counter in state</li>
              <li><code class="bg-zinc-100 px-1.5 py-0.5 rounded text-xs font-mono">log</code> &rarr; LogMessage &mdash; logs the message payload</li>
            </ul>
            <ol class="list-decimal list-inside text-sm text-zinc-600 space-y-1 mt-2">
              <li>Navigate to <strong>Dispatch Signal</strong> (or use the Assignments link)</li>
              <li>Click an agent card to select it (highlighted with a teal border)</li>
              <li>Enter a signal type (e.g., <code class="bg-zinc-100 px-1 rounded text-xs">ping</code>)</li>
              <li>Enter a JSON payload with your message data</li>
              <li>Click <strong>Dispatch</strong> &mdash; the Result panel shows confirmation</li>
            </ol>
          </div>
        </section>

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- OPERATE --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="operate" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">Operate</h2>

          <div id="dashboard" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Dashboard</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The Dashboard is your operational command center. It displays four real-time
              KPI cards at the top and three detail panels below.
            </p>
            <div class="grid grid-cols-2 gap-3 text-sm">
              <div class="bg-zinc-50 rounded p-2.5 border">
                <strong class="text-zinc-700">Running Agents</strong>
                <p class="text-xs text-zinc-500">Count of live agent processes from the Roster</p>
              </div>
              <div class="bg-zinc-50 rounded p-2.5 border">
                <strong class="text-zinc-700">Active Workflows</strong>
                <p class="text-xs text-zinc-500">Number of workflows defined for the workspace</p>
              </div>
              <div class="bg-zinc-50 rounded p-2.5 border">
                <strong class="text-zinc-700">Signals/hr</strong>
                <p class="text-xs text-zinc-500">Signal throughput over the last 60 minutes</p>
              </div>
              <div class="bg-zinc-50 rounded p-2.5 border">
                <strong class="text-zinc-700">Recent Errors</strong>
                <p class="text-xs text-zinc-500">Error count from observability logs</p>
              </div>
            </div>
            <p class="text-sm text-zinc-600">
              The <strong>Quick Actions</strong> panel provides one-click navigation to
              hire agents or create workflows.
            </p>
          </div>

          <div id="agents" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Agents (Roster)</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The Roster page manages the lifecycle of Jido agent processes. Each agent
              is displayed as a card showing its name, status badge, and template type.
            </p>
            <h4 class="text-sm font-semibold text-zinc-700 mt-2">Hiring an Agent</h4>
            <p class="text-sm text-zinc-600">
              Click <strong>Hire</strong> to open the hire modal. Enter a unique name and
              confirm. The system calls <code class="bg-zinc-100 px-1 rounded text-xs">Roster.hire/3</code>
              which starts a supervised <code class="bg-zinc-100 px-1 rounded text-xs">BareAgent</code>
              process and persists the instance record to the database.
            </p>
            <h4 class="text-sm font-semibold text-zinc-700 mt-2">Stopping an Agent</h4>
            <p class="text-sm text-zinc-600">
              Click the red <strong>Stop</strong> link on any agent card. A confirmation
              modal appears warning that in-flight tasks will be cancelled. On confirm,
              the agent process is terminated and the database record is updated. If the
              process has already died (e.g., after a server restart), the record is
              still cleaned up gracefully.
            </p>
            <h4 class="text-sm font-semibold text-zinc-700 mt-2">Agent Detail View</h4>
            <p class="text-sm text-zinc-600">
              Click <strong>View</strong> to navigate to <code class="bg-zinc-100 px-1 rounded text-xs">/agents/:name</code>.
              This page displays the agent's current state, PID, and template configuration.
            </p>
          </div>

          <div id="workflows" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Workflows</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The Workflow Builder provides a visual DAG (Directed Acyclic Graph) canvas
              for composing multi-step agent pipelines. Each workflow consists of named
              steps connected by edges.
            </p>
            <h4 class="text-sm font-semibold text-zinc-700 mt-2">Creating a Workflow</h4>
            <ol class="list-decimal list-inside text-sm text-zinc-600 space-y-1">
              <li>Enter a workflow name and click <strong>Create Workflow</strong></li>
              <li>Select the workflow from the dropdown to load its canvas</li>
              <li>Add steps using the "Add Step" form with a name and kind</li>
            </ol>
            <h4 class="text-sm font-semibold text-zinc-700 mt-2">Step Types</h4>
            <ul class="text-sm text-zinc-600 space-y-1">
              <li><span class="inline-block w-3 h-3 rounded-sm bg-emerald-500 mr-1.5 align-middle"></span><strong>Action</strong> &mdash; Executes a Jido Action on an agent</li>
              <li><span class="inline-block w-3 h-3 rounded-sm bg-blue-500 mr-1.5 align-middle"></span><strong>Emit</strong> &mdash; Emits a signal to the next step</li>
              <li><span class="inline-block w-3 h-3 rounded-sm bg-amber-500 mr-1.5 align-middle"></span><strong>Condition</strong> &mdash; Branches the flow based on a predicate</li>
              <li><span class="inline-block w-3 h-3 rounded-sm bg-violet-500 mr-1.5 align-middle"></span><strong>Transform</strong> &mdash; Transforms data between steps</li>
            </ul>
            <h4 class="text-sm font-semibold text-zinc-700 mt-2">Canvas Interaction</h4>
            <p class="text-sm text-zinc-600">
              <strong>Drag</strong> nodes to reposition them. <strong>Click</strong> a node
              to select it and view its configuration. <strong>Scroll wheel</strong> to zoom
              in/out. Drag from a node's right edge to create an edge to another node.
            </p>
          </div>

          <div id="schedules" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Schedules</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              Schedules allow you to trigger agent actions on a recurring basis using
              cron expressions. Each schedule is tied to a template and workspace.
            </p>
            <ol class="list-decimal list-inside text-sm text-zinc-600 space-y-1">
              <li>Navigate to <strong>Operate &rarr; Schedules</strong></li>
              <li>Enter a cron expression (e.g., <code class="bg-zinc-100 px-1 rounded text-xs">*/5 * * * *</code> for every 5 minutes)</li>
              <li>Select a timezone and click <strong>Schedule</strong></li>
              <li>Active schedules appear in the list with a <strong>Cancel</strong> option</li>
            </ol>
          </div>

          <div id="dispatch" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Dispatch Signal</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The Dispatch Signal page (<code class="bg-zinc-100 px-1 rounded text-xs">/assignments/new</code>)
              is the primary interface for sending signals to running agents.
            </p>
            <p class="text-sm text-zinc-600">
              The page shows all running agents as selectable cards on the left, with a
              Result panel on the right. Select an agent, enter a signal type and JSON
              payload, then click <strong>Dispatch</strong>. The result shows either a
              success confirmation or an error message.
            </p>
            <div class="bg-blue-50 border border-blue-200 rounded-lg p-3 text-sm text-blue-800">
              <strong>Tip:</strong> Signals are dispatched asynchronously via
              <code class="text-xs">Signals.cast/3</code>. The "dispatched async &mdash; signal enqueued"
              response means the signal was accepted into the agent's mailbox. Check the
              <strong>Execution</strong> page for processing results.
            </div>
          </div>
        </section>

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- CONFIGURE --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="configure" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">Configure</h2>

          <div id="templates" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Templates</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              Templates are agent blueprints. Each template defines a name, slug, status,
              and configuration JSON. The configuration can include signal routes, plugins,
              sensors, identity profiles, memory spaces, and threads.
            </p>
            <p class="text-sm text-zinc-600">
              Navigate to <strong>Configure &rarr; Templates</strong> to view and create
              templates. Click a template to edit its configuration on the detail page
              (<code class="bg-zinc-100 px-1 rounded text-xs">/templates/:id/edit</code>).
            </p>
          </div>

          <div id="skills" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Skills</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The Skills page displays a catalog of all discovered Jido Actions available
              in the runtime. Use the search field to filter actions by name.
              Select an action to inspect its module, parameters, and documentation.
            </p>
          </div>

          <div id="directives" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Directives</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The Directive Composer is an interactive tool for building runtime
              instructions. Select from 11 directive types and configure their parameters:
            </p>
            <div class="grid grid-cols-3 gap-2 text-xs text-zinc-600">
              <span class="bg-zinc-50 rounded px-2 py-1 border font-mono">emit</span>
              <span class="bg-zinc-50 rounded px-2 py-1 border font-mono">error</span>
              <span class="bg-zinc-50 rounded px-2 py-1 border font-mono">spawn</span>
              <span class="bg-zinc-50 rounded px-2 py-1 border font-mono">spawn_agent</span>
              <span class="bg-zinc-50 rounded px-2 py-1 border font-mono">adopt_child</span>
              <span class="bg-zinc-50 rounded px-2 py-1 border font-mono">stop_child</span>
              <span class="bg-zinc-50 rounded px-2 py-1 border font-mono">schedule</span>
              <span class="bg-zinc-50 rounded px-2 py-1 border font-mono">run_instruction</span>
              <span class="bg-zinc-50 rounded px-2 py-1 border font-mono">stop</span>
              <span class="bg-zinc-50 rounded px-2 py-1 border font-mono">cron</span>
              <span class="bg-zinc-50 rounded px-2 py-1 border font-mono">cron_cancel</span>
            </div>
            <p class="text-sm text-zinc-600 mt-2">
              After configuring, click <strong>Preview</strong> to see the generated Elixir
              struct, or <strong>Export</strong> to download the code.
            </p>
          </div>

          <div id="teams" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Teams (Pods)</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              Teams manage pod topologies &mdash; groups of cooperating agents with
              coordination strategies. Create a team by specifying a name and selecting a
              strategy:
            </p>
            <ul class="text-sm text-zinc-600 space-y-1">
              <li><strong>Round Robin</strong> &mdash; Distributes work evenly across members</li>
              <li><strong>Broadcast</strong> &mdash; Sends every signal to all members</li>
              <li><strong>Random</strong> &mdash; Routes signals to a randomly selected member</li>
            </ul>
          </div>
        </section>

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- OBSERVE --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="observe" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">Observe</h2>

          <div id="execution" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Execution Monitor</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The Execution page provides a real-time event timeline of agent activity.
              Events are streamed via Phoenix PubSub as they occur. Click any event to
              expand its detail view showing the full payload, timing, and agent state.
            </p>
            <p class="text-sm text-zinc-600">
              Navigate to <code class="bg-zinc-100 px-1 rounded text-xs">/execution/:agent_id</code>
              to view execution history for a specific agent.
            </p>
          </div>

          <div id="traces" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Traces</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The Traces page displays signal trace records logged by the observability
              subsystem. Each trace shows the signal type, target agent, timestamp, and
              payload. Use the type filter to narrow results.
            </p>
          </div>

          <div id="audit" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Audit Log</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The Audit page provides a chronological record of all administrative actions:
              agent hires/stops, template changes, workflow modifications, and configuration
              updates. Each entry shows the actor (user email), action type, timestamp,
              and affected resource.
            </p>
          </div>

          <div id="debug" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Debug Console</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The Debug page allows you to toggle debug mode globally or per-agent. When
              enabled, agents emit detailed instrumentation events. The page also shows
              panels for recent errors and trace data to help diagnose issues.
            </p>
          </div>
        </section>

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- ADMIN --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="admin" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">Admin</h2>

          <div id="settings" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Settings</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The Settings page manages integrations and secrets. Add key-value pairs for
              API keys, tokens, and configuration values. Secret values are stored
              encrypted in the database and displayed as masked strings in the UI.
            </p>
          </div>

          <div id="workspaces" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Workspaces</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              Workspaces provide data isolation for multi-tenant or multi-environment
              deployments. Each workspace has its own agents, templates, workflows, and
              audit trail. Create workspaces with a unique name and slug. The default
              workspace (ID 1) is provisioned automatically.
            </p>
          </div>
        </section>

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- ADVANCED --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="advanced" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">Advanced</h2>

          <div id="state-ops" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">State Ops</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The State Ops editor lets you compose and preview state mutation operations.
              Provide a current state JSON blob, select an operation, and enter a payload
              to see the resulting state. Supported operations:
            </p>
            <ul class="text-sm text-zinc-600 space-y-1">
              <li><code class="bg-zinc-100 px-1.5 py-0.5 rounded text-xs font-mono">set_state</code> &mdash; Merges new attributes into current state</li>
              <li><code class="bg-zinc-100 px-1.5 py-0.5 rounded text-xs font-mono">replace_state</code> &mdash; Replaces the entire state</li>
              <li><code class="bg-zinc-100 px-1.5 py-0.5 rounded text-xs font-mono">delete_keys</code> &mdash; Removes specified keys from state</li>
              <li><code class="bg-zinc-100 px-1.5 py-0.5 rounded text-xs font-mono">set_path</code> &mdash; Sets a value at a nested path</li>
              <li><code class="bg-zinc-100 px-1.5 py-0.5 rounded text-xs font-mono">delete_path</code> &mdash; Deletes a value at a nested path</li>
            </ul>
          </div>

          <div id="hierarchy" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Hierarchy</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The Hierarchy page visualizes parent-child relationships between agents.
              Agents can adopt children or spawn subordinate agents, creating a supervision
              tree visible in this view.
            </p>
          </div>

          <div id="vault" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Vault</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The Vault provides secure storage for sensitive configuration that agents
              may need at runtime, separate from the Settings integration secrets.
            </p>
          </div>

          <div id="pools" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Pools</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              Resource Pools manage shared resources (connections, workers, rate limiters)
              that agents can check out and return. Configure pool size, overflow limits,
              and checkout timeouts.
            </p>
          </div>

          <div id="blocks" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Block Library</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The Block Library catalogs reusable building blocks (actions, sensors, plugins)
              that can be composed into agent templates. Browse, search, and inspect blocks
              from the catalog. Use the Block Editor to create custom blocks.
            </p>
          </div>

          <div id="identity" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Identity Profiles</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              Identity profiles define persona configurations for agents. Each profile
              includes a name, persona description, and capabilities list. Profiles are
              stored in the template configuration.
            </p>
          </div>

          <div id="threads" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Threads</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              Threads are named conversation contexts within a template. Create thread
              entries (e.g., "incident-room", "planning-session") that agents can use
              to maintain separate conversation histories.
            </p>
          </div>

          <div id="memory-spaces" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Memory Spaces</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              Memory spaces define named storage partitions for agent knowledge bases.
              Each space is a logical namespace where agents can store and retrieve
              long-term memory entries. Spaces are configured per-template.
            </p>
          </div>
        </section>

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- REFERENCE --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="reference" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">Reference</h2>

          <div id="glossary-ref" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Glossary</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              A complete glossary of Jido terminology is available at
              <.link navigate={~p"/glossary"} class="text-emerald-600 hover:underline font-medium">/glossary</.link>.
              Key terms include Agent, Action, Signal, Directive, StateOp, Plugin, Sensor,
              Pod, Strategy, and Template.
            </p>
          </div>

          <div id="keyboard-shortcuts" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Keyboard Shortcuts</h3>
            <dl class="text-sm space-y-2">
              <div class="flex items-center gap-3">
                <kbd class="px-2 py-0.5 bg-zinc-100 rounded text-xs font-mono border">&#8984;K</kbd>
                <span class="text-zinc-600">Open search (planned)</span>
              </div>
              <div class="flex items-center gap-3">
                <kbd class="px-2 py-0.5 bg-zinc-100 rounded text-xs font-mono border">Esc</kbd>
                <span class="text-zinc-600">Close modals and dialogs</span>
              </div>
            </dl>
          </div>

          <div id="signal-types" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Built-in Signal Types</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">
              The BareAgent template includes these signal-to-action route mappings:
            </p>
            <table class="ui-table text-sm mt-2">
              <thead>
                <tr>
                  <th class="py-2 px-3 text-left text-xs uppercase tracking-wide text-zinc-500 font-medium border-b-2 border-zinc-200">Signal Type</th>
                  <th class="py-2 px-3 text-left text-xs uppercase tracking-wide text-zinc-500 font-medium border-b-2 border-zinc-200">Action Module</th>
                  <th class="py-2 px-3 text-left text-xs uppercase tracking-wide text-zinc-500 font-medium border-b-2 border-zinc-200">Description</th>
                </tr>
              </thead>
              <tbody>
                <tr><td class="py-2 px-3 border-b border-zinc-100 font-mono text-xs">ping</td><td class="py-2 px-3 border-b border-zinc-100">Echo</td><td class="py-2 px-3 border-b border-zinc-100 text-zinc-500">Returns the payload unchanged</td></tr>
                <tr><td class="py-2 px-3 border-b border-zinc-100 font-mono text-xs">transform</td><td class="py-2 px-3 border-b border-zinc-100">TransformData</td><td class="py-2 px-3 border-b border-zinc-100 text-zinc-500">Applies data transformations</td></tr>
                <tr><td class="py-2 px-3 border-b border-zinc-100 font-mono text-xs">increment</td><td class="py-2 px-3 border-b border-zinc-100">IncrementCounter</td><td class="py-2 px-3 border-b border-zinc-100 text-zinc-500">Increments a counter in agent state</td></tr>
                <tr><td class="py-2 px-3 font-mono text-xs">log</td><td class="py-2 px-3">LogMessage</td><td class="py-2 px-3 text-zinc-500">Logs the message to the system logger</td></tr>
              </tbody>
            </table>
          </div>
        </section>

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- ACTIVE INFERENCE --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="active-inference" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">Active Inference</h2>
          <div id="what-is-active-inference" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">What is Active Inference?</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">Active Inference is a framework from computational neuroscience where agents maintain probabilistic beliefs about their environment and select actions to minimize expected surprise. Agents use a generative model (POMDP) encoding how hidden states produce observations and how actions change states.</p>
          </div>
          <div id="creating-generative-model" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Creating a Generative Model</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">A generative model consists of four matrices: A (likelihood &mdash; how states generate observations), B (transition &mdash; how actions change states), C (preferences &mdash; what observations the agent prefers), and D (prior &mdash; initial beliefs). Use the Model Builder or choose from four presets: Forager, Thermostat, Trader, and T-Maze. Click any preset on the Active Inference page to load its model &mdash; the Belief State visualization and Policy Evaluation charts update instantly showing posterior probabilities and Expected Free Energy scores.</p>
          </div>
          <div id="understanding-belief-states" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Understanding Belief States</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">A belief state is the agent's posterior probability distribution over hidden states. When an observation arrives, beliefs are updated via Bayesian inference. The entropy of beliefs measures uncertainty; surprise measures how unexpected an observation is given current beliefs. Use the Observe buttons on the Active Inference page to submit observations and watch beliefs shift in real-time.</p>
          </div>
          <div id="building-ai-agent" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Building an Active Inference Agent</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">Create an agent with the Active Inference strategy. Attach a generative model, then send observations. The agent updates beliefs, evaluates candidate policies by expected free energy (balancing exploration and exploitation), and selects the policy that minimizes EFE. Use the Active Inference Plugin for composable integration.</p>
          </div>
        </section>

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- LLM AGENTS --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="llm-agents" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">LLM Agents</h2>
          <div id="configuring-llm-provider" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Configuring an LLM Provider</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">JidoBuilder supports three LLM providers: Anthropic (Claude), OpenAI (GPT-4), and a deterministic Mock provider for testing. Visit the LLM Config page to select a provider and model, adjust temperature and max tokens, write a system prompt, and save the configuration. The model dropdown updates dynamically when you switch providers.</p>
          </div>
          <div id="creating-llm-agent" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Creating an LLM Agent</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">An LLM agent uses the LLM Strategy to process messages. It converts available actions into LLM tool schemas, sends the conversation to the provider, and executes any tool_use responses in a loop until the LLM returns a text response or hits the iteration limit.</p>
          </div>
          <div id="tool-use-conversations" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Tool Use and Conversations</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">The Tool Bridge converts Jido Actions into LLM-compatible tool definitions automatically via Action.Tool.to_tool/1. When the LLM requests a tool call, the bridge resolves the action, converts parameters, executes it, and formats the result back into the conversation.</p>
          </div>
          <div id="memory-augmented-agents" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Memory-Augmented Agents</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">LLM agents can read from and write to Memory spaces using three built-in tool actions: MemoryRead, MemoryWrite, and MemorySearch. This enables persistent knowledge storage across conversations.</p>
          </div>
        </section>

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- AGENT FACTORY --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="agent-factory" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">Agent Factory</h2>
          <div id="composing-templates" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Composing Templates</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">The Template Composer merges routes, state fields, and plugins from multiple templates into a single composed definition. It detects conflicts (duplicate signal routes, type mismatches in state fields) and can force-merge when conflicts are acceptable.</p>
          </div>
          <div id="cloning-customizing" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Cloning and Customizing</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">Clone any template config with selective overrides using the Versioning module. Create version snapshots, compute diffs between versions, and rollback to any previous configuration.</p>
          </div>
          <div id="deploying-agent-teams" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Deploying Agent Teams</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">The Team Deployer takes a Solution definition (template slugs + skill slugs + workflow slugs) and deploys multiple agents as a coordinated team. Plan the deployment, validate it, then deploy in one step.</p>
          </div>
        </section>

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- NOTEBOOK --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="notebook-guide" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">Notebook</h2>
          <div id="writing-code-cells" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Writing Code Cells</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">The Notebook provides a LiveBook-style interactive editor. Write Elixir code in the editor, click Run Cell to execute, and see results inline below the editor &mdash; green for success, red for errors. Variables persist between cells, so you can build up complex expressions step by step. Timeout protection prevents runaway computations.</p>
          </div>
          <div id="loading-editing-agents" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Loading and Editing Agents</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">Load any running agent or template definition into a notebook session. Inspect state, modify configuration, and test changes interactively before deploying.</p>
          </div>
          <div id="testing-exporting" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Testing and Exporting</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">Send test signals from notebook cells, inspect results inline, and step through action execution. Export successful cells as a standalone Elixir module file.</p>
          </div>
        </section>

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- SOLUTIONS --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="solutions-guide" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">Solutions</h2>
          <div id="deploying-business-solution" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Deploying a Business Solution</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">Solutions are pre-composed multi-agent packages: Help Desk, Content Pipeline, DevOps Suite, Sales Pipeline, and Knowledge Base. Each bundles template definitions, skill packs, and workflow configurations. Click the Deploy button next to any solution on the Solutions or Factory page to instantly provision a coordinated agent team. A status banner confirms the deployment and shows the agent count.</p>
          </div>
          <div id="customizing-solutions" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Customizing Solutions</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">After deploying a solution, customize individual agents by modifying their templates, attaching additional skills, or adjusting LLM configurations. Use the Factory to compose new template combinations.</p>
          </div>
        </section>

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- TEMPLATE LIBRARY --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="template-library-guide" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">Template Library</h2>
          <div id="browsing-installing-templates" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Browsing and Installing Templates</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">The Template Library provides a searchable catalog of 61 actions across 10 categories and 5 skill packs. Switch between Actions and Skills tabs, use the search bar to filter by name, or click category buttons to narrow results. All actions and skills are displayed with their metadata for easy discovery.</p>
          </div>
          <div id="creating-shareable-templates" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Creating Shareable Templates</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">Build custom templates by composing actions, configuring routes, setting state fields, and attaching plugins. Version your templates for rollback support and share them across workspaces.</p>
          </div>
        </section>

        <%!-- ═══════════════════════════════════════════ --%>
        <%!-- ABOUT --%>
        <%!-- ═══════════════════════════════════════════ --%>
        <section id="about" class="guide-section space-y-6">
          <h2 class="text-2xl font-bold text-zinc-900 border-b pb-3">About</h2>

          <div id="about-author" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">About the Author</h3>
            <div class="flex gap-6 items-start">
              <div class="space-y-3">
                <p class="text-sm text-zinc-600 leading-relaxed"><strong>Michael Polzin</strong> is a C-Suite IT Executive, Solution Architect, and author with 35+ years in IT operations and service management. He helps organizations orchestrate complex technology, people, and processes into coherent, reliable services that actually move the business forward. He is the author of <em>The ORCHESTRATE Method</em>, co-author of <em>Run on Rhythm</em>, and creator of the AI Usage Maturity Model in <em>Level Up</em>.</p>
                <p class="text-sm text-zinc-600 leading-relaxed">Michael is the Owner of Action Based Consulting and previously served as CEO of Leeward Business Advisors. He holds a degree from Cardinal Stritch University and is based in the Greater Milwaukee area.</p>
                <div class="flex flex-wrap gap-2 text-xs">
                  <a href="https://www.linkedin.com/in/mpolzin/" target="_blank" class="bg-blue-100 text-blue-700 px-2 py-1 rounded hover:bg-blue-200">LinkedIn</a>
                  <a href="https://github.com/TMDLRG" target="_blank" class="bg-zinc-100 text-zinc-700 px-2 py-1 rounded hover:bg-zinc-200">GitHub</a>
                  <a href="https://dev.to/tmdlrg" target="_blank" class="bg-zinc-100 text-zinc-700 px-2 py-1 rounded hover:bg-zinc-200">Blog</a>
                  <a href="https://www.youtube.com/@NewsWright" target="_blank" class="bg-red-100 text-red-700 px-2 py-1 rounded hover:bg-red-200">YT: @NewsWright</a>
                  <a href="https://www.youtube.com/@ORCHESTRATEMaster" target="_blank" class="bg-red-100 text-red-700 px-2 py-1 rounded hover:bg-red-200">YT: @ORCHESTRATEMaster</a>
                  <a href="mailto:mpolzin@zimzap.com" class="bg-emerald-100 text-emerald-700 px-2 py-1 rounded hover:bg-emerald-200">mpolzin@zimzap.com</a>
                </div>
              </div>
            </div>
          </div>

          <div id="about-method" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">The ORCHESTRATE Method</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">JidoBuilder was built on <strong>The ORCHESTRATE Method</strong> &mdash; a prompting framework that makes AI work like magic. It provides structure, context, and intentionality to AI interactions, enabling professional-grade outputs.</p>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <a href="https://www.amazon.com/ORCHESTRATE-Prompting-Professional-AI-Outputs-ebook/dp/B0G2B9LG6V" target="_blank" class="p-4 border rounded hover:border-blue-300 hover:bg-blue-50 transition-colors block">
                <div class="font-semibold text-sm">The ORCHESTRATE Method</div>
                <div class="text-xs text-zinc-500 mt-1">A Prompting Framework for Professional AI Outputs</div>
                <div class="text-xs text-blue-600 mt-2">Buy on Amazon &rarr;</div>
              </a>
              <a href="https://www.amazon.com/Run-Rhythm-Build-business-doesnt-ebook/dp/B0G1Y8L9D7" target="_blank" class="p-4 border rounded hover:border-blue-300 hover:bg-blue-50 transition-colors block">
                <div class="font-semibold text-sm">Run on Rhythm</div>
                <div class="text-xs text-zinc-500 mt-1">Build a business that doesn't run you &mdash; wisdom and AI cognition shaping</div>
                <div class="text-xs text-blue-600 mt-2">Buy on Amazon &rarr;</div>
              </a>
              <a href="https://www.amazon.com/Level-Up-Usage-Maturity-Model-ebook/dp/B0G2FHBJ4W" target="_blank" class="p-4 border rounded hover:border-blue-300 hover:bg-blue-50 transition-colors block">
                <div class="font-semibold text-sm">Level Up: The AI Usage Maturity Model</div>
                <div class="text-xs text-zinc-500 mt-1">Infer your path to AI Business Success</div>
                <div class="text-xs text-blue-600 mt-2">Buy on Amazon &rarr;</div>
              </a>
            </div>
            <div class="mt-3 p-3 bg-zinc-50 border rounded text-sm">
              <p class="text-zinc-600">Rep the movement: <a href="https://iamhitl.com" target="_blank" class="text-blue-600 hover:underline font-semibold">IAMHITL.com</a> &mdash; merch for humans in the loop.</p>
            </div>
          </div>

          <div id="about-projects" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">Other Projects by Michael Polzin</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <a href="https://milwaukeeafterdark.onrender.com/" target="_blank" class="p-3 border rounded hover:border-blue-300 hover:bg-blue-50 transition-colors block">
                <div class="font-semibold text-sm">Milwaukee After Dark</div>
                <div class="text-xs text-zinc-500">Interactive map-based nightlife exploration game</div>
              </a>
              <a href="https://bayes-museum.vercel.app/" target="_blank" class="p-3 border rounded hover:border-blue-300 hover:bg-blue-50 transition-colors block">
                <div class="font-semibold text-sm">Bayes Museum</div>
                <div class="text-xs text-zinc-500">Interactive exhibits about belief updating &mdash; priors, likelihoods, and posteriors</div>
              </a>
              <a href="https://orc-active-inference.vercel.app/" target="_blank" class="p-3 border rounded hover:border-blue-300 hover:bg-blue-50 transition-colors block">
                <div class="font-semibold text-sm">ORC Active Inference</div>
                <div class="text-xs text-zinc-500">Active Inference visualization and learning platform</div>
              </a>
              <a href="https://app-omega-gray.vercel.app/" target="_blank" class="p-3 border rounded hover:border-blue-300 hover:bg-blue-50 transition-colors block">
                <div class="font-semibold text-sm">App Omega</div>
                <div class="text-xs text-zinc-500">AI application platform</div>
              </a>
              <a href="https://67-game-mu.vercel.app/" target="_blank" class="p-3 border rounded hover:border-blue-300 hover:bg-blue-50 transition-colors block">
                <div class="font-semibold text-sm">67 Game</div>
                <div class="text-xs text-zinc-500">Interactive strategy game</div>
              </a>
              <a href="https://solutionwrightwebsite.vercel.app/" target="_blank" class="p-3 border rounded hover:border-blue-300 hover:bg-blue-50 transition-colors block">
                <div class="font-semibold text-sm">SolutionWright</div>
                <div class="text-xs text-zinc-500">Coming soon &mdash; AI solution delivery platform</div>
              </a>
            </div>
          </div>

          <div id="about-build" class="guide-section space-y-3">
            <h3 class="text-lg font-semibold text-zinc-800">How This Was Built</h3>
            <p class="text-sm text-zinc-600 leading-relaxed">JidoBuilder v2 was built in <strong>under 3 calendar days</strong>. The builder folder was created on April 11, 2026 at 4:46 PM CDT. By April 13, 2026 at 1:12 AM CDT &mdash; approximately 33 hours later &mdash; the platform had 388 passing tests, 15 interactive LiveView pages, 13 MCP tools, 61 registered actions, a full Active Inference perception-action loop with real-time SVG visualization, an LLM strategy with tool bridging across 3 providers, a composable Agent Factory with team deployment, and an interactive Elixir notebook with persistent bindings. Built entirely using AI-assisted development with the ORCHESTRATE Method.</p>
            <div class="p-4 bg-emerald-50 border border-emerald-200 rounded text-sm text-emerald-800">
              <p class="font-semibold">Founding Partner seats are open.</p>
              <p class="mt-1">Interested in partnering on AI agent delivery? Email <a href="mailto:mpolzin@zimzap.com" class="underline font-semibold">mpolzin@zimzap.com</a> to learn more.</p>
            </div>
          </div>
        </section>

        <%!-- Footer --%>
        <footer class="border-t pt-6 text-center text-sm text-zinc-400 space-y-2">
          <p>Jido Builder v0.1.0 &mdash; Built on the <a href="https://hexdocs.pm/jido" class="text-emerald-600 hover:underline">Jido Agent Framework</a></p>
          <p>Built on <a href="https://www.amazon.com/ORCHESTRATE-Prompting-Professional-AI-Outputs-ebook/dp/B0G2B9LG6V" class="text-emerald-600 hover:underline">The ORCHESTRATE Method</a> | Wisdom from <a href="https://www.amazon.com/Run-Rhythm-Build-business-doesnt-ebook/dp/B0G1Y8L9D7" class="text-emerald-600 hover:underline">Run on Rhythm</a> | <a href="https://iamhitl.com" class="text-emerald-600 hover:underline">IAMHITL.com</a></p>
          <p>&copy; 2026 <a href="https://www.linkedin.com/in/mpolzin/" class="text-emerald-600 hover:underline">Michael Polzin</a> &mdash; <a href="mailto:mpolzin@zimzap.com" class="text-emerald-600 hover:underline">mpolzin@zimzap.com</a></p>
        </footer>

      </article>
    </div>
    """
  end
end
