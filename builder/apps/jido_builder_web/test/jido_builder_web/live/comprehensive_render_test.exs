defmodule JidoBuilderWeb.Live.ComprehensiveRenderTest do
  @moduledoc "Story 10.2 — Every page renders without error."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  @live_routes [
    "/",
    "/roster",
    "/workflows",
    "/schedules",
    "/teams",
    "/settings",
    "/assignments/new",
    "/templates",
    "/skills",
    "/directives",
    "/work-styles",
    "/capability-packs",
    "/watchers",
    "/hierarchy",
    "/state-ops",
    "/audit",
    "/vault",
    "/traces",
    "/pools",
    "/workspaces",
    "/blocks",
    "/ejector",
    "/threads",
    "/memory",
    "/identity",
    "/glossary",
    "/onboarding",
    "/debug",
    "/error-policy",
    "/orphans",
    "/guide",
    "/metrics-dashboard",
    "/marketplace",
    "/execution",
    "/active-inference",
    "/llm-config",
    "/factory",
    "/solutions",
    "/template-library",
    "/notebook",
    "/skills-manager"
  ]

  for route <- @live_routes do
    test "#{route} renders 200", %{conn: conn} do
      {:ok, _lv, html} = live(conn, unquote(route))
      assert html =~ "app-shell"
    end
  end
end
