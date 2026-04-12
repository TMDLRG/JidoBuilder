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
    end
  end
end
