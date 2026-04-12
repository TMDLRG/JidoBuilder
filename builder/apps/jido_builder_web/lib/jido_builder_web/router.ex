defmodule JidoBuilderWeb.Router do
  use JidoBuilderWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {JidoBuilderWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", JidoBuilderWeb do
    pipe_through(:api)

    get("/healthz", HealthController, :healthz)
    get("/readyz", HealthController, :readyz)
  end

  scope "/", JidoBuilderWeb do
    pipe_through(:browser)

    live_session :default do
      live("/", DashboardLive, :index)
      live("/roster", RosterLive, :index)
      live("/agents/:id", AgentLive, :show)
      live("/workflows", WorkflowBuilderLive, :index)
      live("/schedules", SchedulesLive, :index)
      live("/teams", TeamsLive, :index)
      live("/settings", SettingsLive, :index)
    end
  end
end
