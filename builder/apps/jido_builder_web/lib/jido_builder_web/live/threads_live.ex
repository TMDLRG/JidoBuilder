defmodule JidoBuilderWeb.ThreadsLive do
  @moduledoc "Phase Final A.9 — Thread explorer with create flow."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Templates

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)
    templates = Templates.list_templates(workspace_id)
    selected = List.first(templates)

    {:ok,
     assign(socket,
       page_title: "Threads",
       templates: templates,
       selected_template_id: selected && selected.id,
       threads: config_list(selected, "threads"),
       saved?: false
     )}
  end

  @impl true
  def handle_event("select_template", %{"template_id" => id}, socket) do
    tid = case Integer.parse(id) do
      {n, ""} -> n
      _ -> nil
    end

    template = if tid, do: Templates.get_template!(tid)
    {:noreply, assign(socket, selected_template_id: tid, threads: config_list(template, "threads"))}
  end

  def handle_event("delete_thread", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    template = Templates.get_template!(socket.assigns.selected_template_id)
    threads = config_list(template, "threads") |> List.delete_at(idx)
    {:ok, updated} = Templates.update_template(template, %{config: Map.put(template.config || %{}, "threads", threads)}, "web")
    {:noreply, assign(socket, threads: config_list(updated, "threads"))}
  end

  def handle_event("create", %{"thread" => %{"name" => name}}, socket) do
    template = Templates.get_template!(socket.assigns.selected_template_id)
    threads = config_list(template, "threads") ++ [%{"name" => name}]
    {:ok, updated} = Templates.update_template(template, %{config: Map.put(template.config || %{}, "threads", threads)}, "web")

    {:noreply, assign(socket, threads: config_list(updated, "threads"), saved?: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>

    <div :if={length(@templates) > 1} class="mb-4">
      <label class="text-xs font-medium text-zinc-600">Template</label>
      <form phx-change="select_template" class="mt-1">
        <select name="template_id" class="ui-input text-sm">
          <option :for={t <- @templates} value={t.id} selected={t.id == @selected_template_id}>{t.name}</option>
        </select>
      </form>
    </div>

    <p class="text-sm text-zinc-500 mb-4">Browse and create thread entries for template context.</p>

    <.card class="max-w-md mb-4">
      <:header>New Thread</:header>
      <form id="thread-form" phx-submit="create" class="flex gap-2">
        <.input_field name="thread[name]" label="" placeholder="incident-room" />
        <.button>Create thread</.button>
      </form>
      <p :if={@saved?} class="text-xs text-emerald-700 mt-2">Thread created.</p>
    </.card>

    <.card>
      <:header>Threads</:header>
      <ul id="threads-list" class="space-y-1 text-sm">
        <li :for={{thread, idx} <- Enum.with_index(@threads)} class="border-b pb-1 flex justify-between items-center">
          <span>{thread["name"]}</span>
          <button phx-click="delete_thread" phx-value-index={idx} class="text-xs text-red-500 hover:text-red-700">Delete</button>
        </li>
      </ul>
      <.empty_state :if={@threads == []} title="No threads" description="No threads yet." icon="chat-bubble-left-right" />
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
