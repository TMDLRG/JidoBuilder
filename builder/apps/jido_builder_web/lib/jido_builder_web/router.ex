defmodule JidoBuilderWeb.Router do
  use JidoBuilderWeb, :router

  import JidoBuilderWeb.UserAuth, only: [fetch_current_user: 2, require_authenticated_user: 2]

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {JidoBuilderWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :api_authenticated do
    plug(:accepts, ["json"])
    plug(JidoBuilderWeb.Plugs.ApiAuth)
    plug(JidoBuilderWeb.Plugs.RateLimit)
  end

  scope "/", JidoBuilderWeb do
    pipe_through(:api)

    get("/healthz", HealthController, :healthz)
    get("/readyz", HealthController, :readyz)
    get("/metrics", MetricsController, :index)
  end

  scope "/api/v1", JidoBuilderWeb.Api.V1 do
    pipe_through(:api)

    get "/openapi.json", OpenApiController, :spec
  end

  scope "/mcp", JidoBuilderWeb.MCP do
    pipe_through(:api_authenticated)

    post "/", McpController, :handle
    get "/sse", SseController, :sse
    post "/messages", SseController, :messages
  end

  scope "/api/v1", JidoBuilderWeb.Api.V1 do
    pipe_through(:api_authenticated)

    resources "/agents", AgentController, only: [:index, :create, :show, :delete], param: "id"
    post "/agents/:id/dispatch", AgentController, :dispatch

    resources "/templates", TemplateController, only: [:index, :create, :show, :delete]
    resources "/workflows", WorkflowController, only: [:index, :create, :show]

    get "/workspace/export", WorkspaceController, :export

    get "/signals", ObservabilityController, :signals
    get "/errors", ObservabilityController, :errors
    get "/correlation/:id", ObservabilityController, :correlation
  end

  scope "/", JidoBuilderWeb do
    pipe_through(:browser)

    live("/login", LoginLive, :new)
    post("/login", SessionController, :create)
    delete("/logout", SessionController, :delete)
  end

  scope "/", JidoBuilderWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :authenticated,
      on_mount: [{JidoBuilderWeb.UserAuth, :ensure_authenticated}, {JidoBuilderWeb.CommandPalette, :default}] do
      live("/", DashboardLive, :index)
      live("/roster", RosterLive, :index)
      live("/agents/:id", AgentLive, :show)
      live("/workflows", WorkflowBuilderLive, :index)
      live("/execution", ExecutionLive, :index)
      live("/execution/:agent_id", ExecutionLive, :show)
      live("/schedules", SchedulesLive, :index)
      live("/teams", TeamsLive, :index)
      live("/settings", SettingsLive, :index)
      live("/assignments/new", Assignments.NewLive, :new)
      live("/templates", Templates.IndexLive, :index)
      live("/templates/:id/edit", Templates.EditLive, :edit)
      live("/actions", Actions.BuilderLive, :index)
      live("/skills", Skills.IndexLive, :index)
      live("/work-styles", WorkStyles.IndexLive, :index)
      live("/directives", Directives.BuilderLive, :index)
      live("/capability-packs", CapabilityPacksLive, :index)
      live("/watchers", WatchersLive, :index)
      live("/hierarchy", HierarchyLive, :index)
      live("/state-ops", StateOpsLive, :index)
      live("/audit", AuditLive, :index)
      live("/vault", VaultLive, :index)
      live("/traces", TracesLive, :index)
      live("/pools", PoolsLive, :index)
      live("/workspaces", WorkspacesLive, :index)
      live("/blocks", BlockLibraryLive, :index)
      live("/editor/:type", BlockEditorLive, :edit)
      live("/ejector", EjectorLive, :index)
      live("/threads", ThreadsLive, :index)
      live("/memory", MemoryLive, :index)
      live("/identity", IdentityLive, :index)
      live("/glossary", GlossaryLive, :index)
      live("/onboarding", OnboardingLive, :index)
      live("/debug", DebugLive, :index)
      live("/error-policy", ErrorPolicyLive, :index)
      live("/orphans", OrphansLive, :index)
      live("/guide", GuideLive, :index)
      live("/metrics-dashboard", MetricsLive, :index)
      live("/marketplace", Plugins.MarketplaceLive, :index)
      # -- v2 routes --
      live("/active-inference", ActiveInferenceLive, :index)
      live("/llm-config", LlmConfigLive, :index)
      live("/factory", FactoryLive, :index)
      live("/solutions", SolutionsLive, :index)
      live("/template-library", TemplateLibraryLive, :index)
      live("/notebook", NotebookLive, :index)
      live("/notebook/:id", NotebookLive, :show)
      live("/skills-manager", SkillsManagerLive, :index)
      live("/agents/:id/chat", AgentChatLive, :show)
      live("/agents/new/llm", LlmAgentWizardLive, :new)
    end
  end
end
