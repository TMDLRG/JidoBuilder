defmodule JidoBuilderWeb.MemoryLive do
  @moduledoc "Phase Final A.10 — Memory spaces persisted in template config."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Templates

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)
    templates = Templates.list_templates(workspace_id)
    selected = List.first(templates)

    {:ok,
     assign(socket,
       page_title: "Memory Spaces",
       selected_template_id: selected && selected.id,
       spaces: config_list(selected, "memory_spaces")
     )}
  end

  @impl true
  def handle_event("create", %{"space" => %{"name" => name}}, socket) do
    template = Templates.get_template!(socket.assigns.selected_template_id)
    spaces = config_list(template, "memory_spaces") ++ [%{"name" => name}]
    {:ok, updated} = Templates.update_template(template, %{config: Map.put(template.config || %{}, "memory_spaces", spaces)}, "web")
    {:noreply, assign(socket, spaces: config_list(updated, "memory_spaces"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <.card class="max-w-md mb-4">
      <:header>Add Memory Space</:header>
      <form id="memory-form" phx-submit="create" class="flex gap-2">
        <input type="text" name="space[name]" placeholder="knowledge-base" class="border rounded px-2 py-1 text-sm flex-1" />
        <.button>Add space</.button>
      </form>
    </.card>

    <.card>
      <:header>Memory Spaces</:header>
      <ul id="memory-spaces-list" class="space-y-1 text-sm">
        <li :for={space <- @spaces} class="border-b pb-1">{space["name"]}</li>
      </ul>
      <.empty_state :if={@spaces == []} title="No memory spaces" description="No memory spaces configured yet." icon="circle-stack" />
    </.card>
    """
  end

  defp config_list(nil, _key), do: []
  defp config_list(template, key), do: get_in(template.config || %{}, [key]) || []

  defp wid(%{"workspace_id" => id}) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end
  defp wid(_), do: 1
end
