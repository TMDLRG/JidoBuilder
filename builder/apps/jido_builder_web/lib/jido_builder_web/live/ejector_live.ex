defmodule JidoBuilderWeb.EjectorLive do
  @moduledoc "Phase 5 — Ejector: export template as standalone Elixir module."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCodegen.Templates, as: CodegenTemplates

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Ejector", preview: nil, error: nil)}
  end

  @impl true
  def handle_event("export", %{"block" => attrs}, socket) do
    block = %{
      type: String.to_atom(attrs["type"] || "action"),
      module: attrs["module"] || "",
      name: attrs["name"] || "",
      description: attrs["description"] || ""
    }

    case CodegenTemplates.render(block) do
      {:ok, source} ->
        {:noreply, assign(socket, preview: source, error: nil)}

      {:error, reason} ->
        {:noreply, assign(socket, preview: nil, error: inspect(reason))}
    end
  end


  @impl true
  def handle_event("download", _params, %{assigns: %{preview: preview}} = socket) when is_binary(preview) do
    filename = "jido_export_#{System.system_time(:millisecond)}.ex"
    {:noreply, push_event(socket, "download", %{filename: filename, content: preview})}
  end

  def handle_event("download", _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div id="ejector-hook" phx-hook="Download">
    <.page_header>{@page_title}</.page_header>
    <p class="text-sm text-zinc-500 mb-4">Export a block definition as a standalone Elixir module (no compile).</p>

    <.card class="max-w-md">
      <:header>Export Block</:header>
      <form id="ejector-form" phx-submit="export" class="space-y-3">
        <div>
          <label class="block text-xs font-medium mb-1">Type</label>
          <select name="block[type]" class="border rounded px-2 py-1 w-full text-sm">
            <option value="action">action</option>
            <option value="agent">agent</option>
            <option value="plugin">plugin</option>
            <option value="sensor">sensor</option>
            <option value="strategy">strategy</option>
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
        <.button>Export as Elixir</.button>
      </form>
    </.card>

    <.card :if={@preview} class="mt-6">
      <:header>Exported Source</:header>
      <pre id="ejector-preview" class="font-mono text-xs whitespace-pre-wrap">{@preview}</pre>
      <div class="mt-3">
        <.button id="ejector-download" phx-click="download">Download source</.button>
      </div>
    </.card>

    <div :if={@error} id="ejector-error" class="mt-4 text-red-600 text-sm">{@error}</div>
    </div>
    """
  end
end
