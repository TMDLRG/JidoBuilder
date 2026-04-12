defmodule JidoBuilderWeb.BlockEditorLive do
  @moduledoc """
  Phase 5 — Generic block editor for action/sensor/plugin/strategy.
  Renders a preview of the generated Elixir source via codegen templates.
  Also serves as the FSM Designer for strategies (states+transitions table).
  """
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCodegen.Templates, as: CodegenTemplates

  @type_labels %{
    "action" => "Action Editor",
    "sensor" => "Sensor Editor",
    "plugin" => "Plugin Editor",
    "strategy" => "Strategy Editor"
  }

  @impl true
  def mount(%{"type" => type}, _session, socket) when is_map_key(@type_labels, type) do
    {:ok,
     assign(socket,
       page_title: @type_labels[type],
       block_type: type,
       preview: nil,
       error: nil
     )}
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Block Editor", block_type: "action", preview: nil, error: nil)}
  end

  @impl true
  def handle_event("preview", %{"block" => attrs}, socket) do
    block = %{
      type: String.to_atom(socket.assigns.block_type),
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
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <form id="editor-form" phx-submit="preview" class="space-y-3 max-w-md mt-4">
      <div>
        <label class="block text-xs font-medium mb-1">Module</label>
        <input type="text" name="block[module]" placeholder="MyApp.MyModule" class="border rounded px-2 py-1 w-full text-sm font-mono" />
      </div>
      <div>
        <label class="block text-xs font-medium mb-1">Name</label>
        <input type="text" name="block[name]" class="border rounded px-2 py-1 w-full text-sm" />
      </div>
      <div>
        <label class="block text-xs font-medium mb-1">Description</label>
        <input type="text" name="block[description]" class="border rounded px-2 py-1 w-full text-sm" />
      </div>
      <button type="submit" class="rounded bg-zinc-900 px-4 py-2 text-white text-xs">Preview Source</button>
    </form>

    <div :if={@preview} id="source-preview" class="mt-6 rounded bg-zinc-50 border p-4">
      <h2 class="text-xs font-semibold mb-2 text-zinc-700">Generated Source</h2>
      <pre class="font-mono text-xs whitespace-pre-wrap"><%= @preview %></pre>
    </div>

    <div :if={@error} id="editor-error" class="mt-4 text-red-600 text-sm"><%= @error %></div>

    <%= if @block_type == "strategy" do %>
    <section class="mt-8">
      <h2 class="text-sm font-semibold mb-2">FSM States + Transitions</h2>
      <p class="text-xs text-zinc-500">Define state machine states and transition rules below.</p>
      <table class="text-xs mt-2 w-full max-w-lg">
        <thead>
          <tr class="border-b text-left text-zinc-500">
            <th class="pb-1">State</th>
            <th class="pb-1">On Signal</th>
            <th class="pb-1">Next State</th>
          </tr>
        </thead>
        <tbody>
          <tr class="border-b"><td class="py-1">idle</td><td>start</td><td>running</td></tr>
          <tr class="border-b"><td class="py-1">running</td><td>complete</td><td>done</td></tr>
          <tr class="border-b"><td class="py-1">running</td><td>error</td><td>failed</td></tr>
        </tbody>
      </table>
    </section>
    <% end %>
    """
  end
end
