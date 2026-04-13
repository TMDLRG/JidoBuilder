defmodule JidoBuilderWeb.CommandPalette do
  @moduledoc """
  Story 6.1 — Command palette mixin for LiveViews.

  Provides `on_mount` hook that adds palette assigns and event handlers
  to any LiveView in the authenticated session.
  """

  import Phoenix.LiveView
  import Phoenix.Component

  @pages [
    %{name: "Dashboard", path: "/", section: "Operate"},
    %{name: "Agents", path: "/roster", section: "Operate"},
    %{name: "Dispatch Signal", path: "/assignments/new", section: "Operate"},
    %{name: "Workflows", path: "/workflows", section: "Operate"},
    %{name: "Schedules", path: "/schedules", section: "Operate"},
    %{name: "Templates", path: "/templates", section: "Configure"},
    %{name: "Actions", path: "/actions", section: "Configure"},
    %{name: "Skills", path: "/skills", section: "Configure"},
    %{name: "Directives", path: "/directives", section: "Configure"},
    %{name: "Teams", path: "/teams", section: "Configure"},
    %{name: "Identity", path: "/identity", section: "Configure"},
    %{name: "Blocks", path: "/blocks", section: "Build"},
    %{name: "State Ops", path: "/state-ops", section: "Build"},
    %{name: "Threads", path: "/threads", section: "Build"},
    %{name: "Memory", path: "/memory", section: "Build"},
    %{name: "Execution", path: "/execution", section: "Observe"},
    %{name: "Traces", path: "/traces", section: "Observe"},
    %{name: "Audit", path: "/audit", section: "Observe"},
    %{name: "Debug", path: "/debug", section: "Observe"},
    %{name: "Settings", path: "/settings", section: "Admin"},
    %{name: "Workspaces", path: "/workspaces", section: "Admin"},
    # -- v2 pages --
    %{name: "Active Inference", path: "/active-inference", section: "Observe"},
    %{name: "LLM Config", path: "/llm-config", section: "Configure"},
    %{name: "Agent Factory", path: "/factory", section: "Build"},
    %{name: "Solutions", path: "/solutions", section: "Admin"},
    %{name: "Template Library", path: "/template-library", section: "Admin"},
    %{name: "Notebook", path: "/notebook", section: "Build"},
    %{name: "Skills Manager", path: "/skills-manager", section: "Configure"},
    %{name: "Metrics Dashboard", path: "/metrics-dashboard", section: "Observe"},
    %{name: "Marketplace", path: "/marketplace", section: "Admin"}
  ]

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign(:palette_open, false)
     |> assign(:palette_query, "")
     |> assign(:palette_results, @pages)
     |> assign(:view_mode, "developer")
     |> attach_hook(:palette_events, :handle_event, &handle_palette_event/3)}
  end

  defp handle_palette_event("toggle_palette", _params, socket) do
    {:halt, assign(socket, palette_open: !socket.assigns.palette_open, palette_query: "", palette_results: @pages)}
  end

  defp handle_palette_event("close_palette", _params, socket) do
    {:halt, assign(socket, palette_open: false)}
  end

  defp handle_palette_event("toggle_view_mode", _params, socket) do
    new_mode = if socket.assigns.view_mode == "developer", do: "business", else: "developer"
    {:halt, assign(socket, view_mode: new_mode)}
  end

  defp handle_palette_event("palette_search", %{"q" => query}, socket) do
    results = filter_pages(query)
    {:halt, assign(socket, palette_query: query, palette_results: results)}
  end

  defp handle_palette_event("global_keydown", %{"key" => "k", "ctrlKey" => true}, socket) do
    {:halt, assign(socket, palette_open: !socket.assigns.palette_open, palette_query: "", palette_results: @pages)}
  end

  defp handle_palette_event("global_keydown", %{"key" => "k", "metaKey" => true}, socket) do
    {:halt, assign(socket, palette_open: !socket.assigns.palette_open, palette_query: "", palette_results: @pages)}
  end

  defp handle_palette_event("global_keydown", _params, socket) do
    {:cont, socket}
  end

  defp handle_palette_event(_event, _params, socket) do
    {:cont, socket}
  end

  defp filter_pages(""), do: @pages
  defp filter_pages(query) do
    q = String.downcase(query)
    Enum.filter(@pages, fn page ->
      String.downcase(page.name) =~ q or String.downcase(page.section) =~ q
    end)
  end

  @doc "All navigable pages for the command palette."
  def pages, do: @pages
end
