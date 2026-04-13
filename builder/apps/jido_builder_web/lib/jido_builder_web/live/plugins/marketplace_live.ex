defmodule JidoBuilderWeb.Plugins.MarketplaceLive do
  @moduledoc "Story 8.3 — Plugin marketplace browser."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.ActionRegistry

  @impl true
  def mount(_params, _session, socket) do
    actions = ActionRegistry.list()
    categories = ActionRegistry.categories()

    {:ok,
     assign(socket,
       page_title: "Plugin Marketplace",
       actions: actions,
       categories: categories,
       selected_category: "all"
     )}
  end

  @impl true
  def handle_event("filter_category", %{"category" => cat}, socket) do
    filtered =
      if cat == "all" do
        ActionRegistry.list()
      else
        ActionRegistry.list_by_category(String.to_existing_atom(cat))
      end

    {:noreply, assign(socket, actions: filtered, selected_category: cat)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Plugin Marketplace</.page_header>

    <div class="flex gap-2 mb-4">
      <button phx-click="filter_category" phx-value-category="all"
        class={"ui-btn " <> if(@selected_category == "all", do: "primary", else: "secondary")}>
        All
      </button>
      <button :for={cat <- @categories} phx-click="filter_category" phx-value-category={cat}
        class={"ui-btn " <> if(@selected_category == to_string(cat), do: "primary", else: "secondary")}>
        {cat |> to_string() |> String.capitalize()}
      </button>
    </div>

    <div class="grid md:grid-cols-3 gap-4">
      <.card :for={action <- @actions}>
        <:header><div class="flex justify-between items-center"><span>{action.name}</span><.badge variant="neutral">{action.category}</.badge></div></:header>
        <p class="text-sm text-zinc-600">{action.description}</p>
        <:footer><span class="text-xs text-zinc-400 font-mono">{action.slug}</span></:footer>
      </.card>
    </div>

    <.empty_state :if={@actions == []} title="No plugins" description="No plugins match the selected filter." icon="puzzle_piece" />
    """
  end
end
