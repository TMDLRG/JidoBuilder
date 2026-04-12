defmodule JidoBuilderWeb.BlockLibraryLive do
  @moduledoc "Phase 5 — Block library + validator."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCodegen.BlockSchema

  @block_types ~w(action agent plugin sensor strategy)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Block Library", types: @block_types, result: nil, error: nil)}
  end

  @impl true
  def handle_event("validate_block", %{"block" => attrs}, socket) do
    block = %{
      type: String.to_atom(attrs["type"] || "action"),
      module: attrs["module"] || "",
      name: attrs["name"] || "",
      description: attrs["description"] || ""
    }

    if BlockSchema.valid?(block) do
      {:noreply, assign(socket, result: "valid", error: nil)}
    else
      {:noreply, assign(socket, result: nil, error: "Invalid block: missing required fields")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p class="text-sm text-zinc-500 mb-4">Browse and validate codegen block definitions.</p>

    <section class="mb-6">
      <h2 class="text-sm font-semibold mb-2">Block Types</h2>
      <ul class="flex gap-2 text-sm">
        <li :for={t <- @types} class="px-3 py-1 border rounded font-mono"><%= t %></li>
      </ul>
    </section>

    <form id="validate-form" phx-submit="validate_block" class="space-y-3 max-w-md">
      <div>
        <label class="block text-xs font-medium mb-1">Type</label>
        <select name="block[type]" class="border rounded px-2 py-1 w-full text-sm">
          <option :for={t <- @types} value={t}><%= t %></option>
        </select>
      </div>
      <div>
        <label class="block text-xs font-medium mb-1">Module</label>
        <input type="text" name="block[module]" class="border rounded px-2 py-1 w-full text-sm font-mono" />
      </div>
      <div>
        <label class="block text-xs font-medium mb-1">Name</label>
        <input type="text" name="block[name]" class="border rounded px-2 py-1 w-full text-sm" />
      </div>
      <div>
        <label class="block text-xs font-medium mb-1">Description</label>
        <input type="text" name="block[description]" class="border rounded px-2 py-1 w-full text-sm" />
      </div>
      <button type="submit" class="rounded bg-zinc-900 px-4 py-2 text-white text-xs">Validate</button>
    </form>

    <div :if={@result} id="validate-result" class="mt-4 text-green-700 text-sm font-semibold"><%= @result %></div>
    <div :if={@error} id="validate-error" class="mt-4 text-red-600 text-sm"><%= @error %></div>
    """
  end
end
