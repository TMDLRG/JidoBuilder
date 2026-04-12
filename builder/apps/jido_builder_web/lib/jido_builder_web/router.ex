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

  scope "/", JidoBuilderWeb do
    pipe_through(:api)

    get("/healthz", HealthController, :healthz)
    get("/readyz", HealthController, :readyz)
    get("/metrics", MetricsController, :index)
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
      on_mount: [{JidoBuilderWeb.UserAuth, :ensure_authenticated}] do
      live("/", DashboardLive, :index)
      live("/roster", RosterLive, :index)
      live("/agents/:id", AgentLive, :show)
      live("/workflows", WorkflowBuilderLive, :index)
      live("/schedules", SchedulesLive, :index)
      live("/teams", TeamsLive, :index)
      live("/settings", SettingsLive, :index)
      live("/assignments/new", Assignments.NewLive, :new)
      live("/templates", Templates.IndexLive, :index)
      live("/templates/:id/edit", Templates.EditLive, :edit)
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
    end
  end
end
