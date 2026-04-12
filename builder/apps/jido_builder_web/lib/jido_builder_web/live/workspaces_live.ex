defmodule JidoBuilderWeb.WorkspacesLive do
  @moduledoc "Phase 4 — Workspaces: partition CRUD."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Agents

  @impl true
  def mount(_params, _session, socket) do
    workspaces = Agents.list_workspaces()

    {:ok,
     assign(socket,
       page_title: "Workspaces",
       workspaces: workspaces,
       partitions: [],
       form_error: nil
     )}
  end

  @impl true
  def handle_event("create_workspace", %{"workspace" => attrs}, socket) do
    user = socket.assigns.current_user

    case Agents.create_workspace(attrs, user.email) do
      {:ok, _ws} ->
        workspaces = Agents.list_workspaces()
        {:noreply, assign(socket, workspaces: workspaces, form_error: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, form_error: inspect(changeset.errors))}
    end
  end

  @impl true
  def handle_event("create_partition", %{"partition" => attrs}, socket) do
    user = socket.assigns.current_user

    case Agents.create_partition(attrs, user.email) do
      {:ok, part} ->
        partitions = Agents.list_partitions(part.workspace_id)
        {:noreply, assign(socket, partitions: partitions, form_error: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, form_error: inspect(changeset.errors))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <section class="mt-4 max-w-md">
      <h2 class="text-sm font-semibold mb-2">New Workspace</h2>
      <form id="workspace-form" phx-submit="create_workspace" class="space-y-3">
        <div>
          <label class="block text-xs font-medium mb-1">Name</label>
          <input type="text" name="workspace[name]" class="border rounded px-2 py-1 w-full text-sm" />
        </div>
        <div>
          <label class="block text-xs font-medium mb-1">Slug</label>
          <input type="text" name="workspace[slug]" class="border rounded px-2 py-1 w-full text-sm" />
        </div>
        <button type="submit" class="rounded bg-zinc-900 px-4 py-2 text-white text-xs">Create</button>
      </form>
    </section>

    <section class="mt-6">
      <h2 class="text-sm font-semibold mb-2">Existing Workspaces</h2>
      <ul id="workspace-list" class="space-y-1 text-sm">
        <li :for={ws <- @workspaces} id={"ws-#{ws.id}"} class="border-b pb-1">
          <span class="font-semibold"><%= ws.name %></span>
          <span class="ml-2 text-zinc-500 font-mono text-xs"><%= ws.slug %></span>
        </li>
      </ul>
      <p :if={@workspaces == []} class="text-sm text-zinc-500">No workspaces.</p>
    </section>

    <section class="mt-6 max-w-md">
      <h2 class="text-sm font-semibold mb-2">New Partition</h2>
      <form id="partition-form" phx-submit="create_partition" class="space-y-3">
        <div>
          <label class="block text-xs font-medium mb-1">Workspace</label>
          <select name="partition[workspace_id]" class="border rounded px-2 py-1 w-full text-sm">
            <option :for={ws <- @workspaces} value={ws.id}><%= ws.name %></option>
          </select>
        </div>
        <div>
          <label class="block text-xs font-medium mb-1">Name</label>
          <input type="text" name="partition[name]" class="border rounded px-2 py-1 w-full text-sm" />
        </div>
        <div>
          <label class="block text-xs font-medium mb-1">Key</label>
          <input type="text" name="partition[key]" class="border rounded px-2 py-1 w-full text-sm" />
        </div>
        <button type="submit" class="rounded bg-zinc-900 px-4 py-2 text-white text-xs">Create Partition</button>
      </form>
      <p :if={@form_error} class="mt-2 text-red-600 text-xs"><%= @form_error %></p>
    </section>

    <section :if={@partitions != []} class="mt-6">
      <h2 class="text-sm font-semibold mb-2">Partitions</h2>
      <ul class="space-y-1 text-sm">
        <li :for={p <- @partitions} class="border-b pb-1">
          <span class="font-semibold"><%= p.name %></span>
          <span class="ml-2 text-zinc-500 font-mono text-xs"><%= p.key %></span>
        </li>
      </ul>
    </section>
    """
  end
end
