defmodule JidoBuilderWeb.Skills.IndexLive do
  @moduledoc "Phase 2.6 — Skills catalog: lists registered Jido actions from Discovery."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.Discovery

  @impl true
  def mount(_params, _session, socket) do
    context = %{workspace_id: 1, actor: "web"}

    actions =
      case Discovery.list_actions(context) do
        {:ok, list} -> list
        _ -> []
      end

    {:ok, assign(socket, page_title: "Skills Catalog", actions: actions)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <ul class="space-y-2 text-sm">
      <li :for={action <- @actions} class="border-b pb-2">
        <span class="font-semibold"><%= inspect(action) %></span>
      </li>
    </ul>

    <p :if={@actions == []} class="text-sm text-zinc-500 mt-4">
      No actions registered in discovery yet.
    </p>
    """
  end
end
