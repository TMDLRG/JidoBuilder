defmodule JidoBuilderWeb.Actions.BuilderLive do
  @moduledoc """
  Story 3.2 — Actions catalog and builder page.

  Shows all registered action patterns grouped by category, with detail
  view for selected actions showing description, schema, and usage.
  """
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.ActionRegistry

  @impl true
  def mount(_params, _session, socket) do
    actions = ActionRegistry.list()
    categories = ActionRegistry.categories()

    {:ok,
     assign(socket,
       page_title: "Actions",
       all_actions: actions,
       filtered_actions: actions,
       categories: categories,
       active_category: nil,
       selected: nil
     )}
  end

  @impl true
  def handle_event("filter_category", %{"category" => category}, socket) do
    cat = String.to_existing_atom(category)
    filtered = ActionRegistry.list_by_category(cat)

    {:noreply, assign(socket, filtered_actions: filtered, active_category: cat)}
  end

  def handle_event("clear_filter", _, socket) do
    {:noreply, assign(socket, filtered_actions: socket.assigns.all_actions, active_category: nil)}
  end

  def handle_event("select_action", %{"slug" => slug}, socket) do
    selected = ActionRegistry.get(slug)
    {:noreply, assign(socket, selected: selected)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Actions</.page_header>

    <div class="flex gap-2 mb-4 flex-wrap">
      <button
        phx-click="clear_filter"
        class={["text-xs px-2 py-1 rounded", if(is_nil(@active_category), do: "bg-zinc-800 text-white", else: "bg-zinc-200 text-zinc-700")]}
      >All</button>
      <button
        :for={cat <- @categories}
        phx-click="filter_category"
        phx-value-category={cat}
        class={["text-xs px-2 py-1 rounded", if(@active_category == cat, do: "bg-zinc-800 text-white", else: "bg-zinc-200 text-zinc-700")]}
      >{cat}</button>
    </div>

    <section class="grid md:grid-cols-3 gap-4">
      <div class="md:col-span-2">
        <div class="grid sm:grid-cols-2 gap-3">
          <button
            :for={action <- @filtered_actions}
            phx-click="select_action"
            phx-value-slug={action.slug}
            class={[
              "text-left border rounded p-3 hover:border-emerald-400 transition-colors",
              if(@selected && @selected.slug == action.slug, do: "border-emerald-500 bg-emerald-50", else: "border-zinc-200")
            ]}
          >
            <div class="font-semibold text-sm">{action.name}</div>
            <div class="text-xs text-zinc-500 mt-1">{action.description}</div>
            <div class="mt-2"><.badge variant="default">{action.category}</.badge></div>
          </button>
        </div>
      </div>

      <div>
        <.card>
          <:header>Action Detail</:header>
          <div :if={@selected} id="action-detail">
            <h3 class="font-semibold text-sm">{@selected.name}</h3>
            <p class="text-xs text-zinc-500 mt-1">{@selected.description}</p>
            <div class="mt-3">
              <span class="text-xs font-medium text-zinc-600">Slug:</span>
              <code class="text-xs ml-1">{@selected.slug}</code>
            </div>
            <div class="mt-1">
              <span class="text-xs font-medium text-zinc-600">Module:</span>
              <code class="text-xs ml-1">{inspect(@selected.module)}</code>
            </div>
            <div class="mt-1">
              <span class="text-xs font-medium text-zinc-600">Category:</span>
              <.badge variant="default">{@selected.category}</.badge>
            </div>
          </div>
          <.empty_state :if={is_nil(@selected)} title="No action selected" description="Click an action to view details." icon="command_line" />
        </.card>
      </div>
    </section>
    """
  end
end
