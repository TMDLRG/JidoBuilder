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
        {:noreply, assign(socket, form_error: format_errors(changeset))}
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
        {:noreply, assign(socket, form_error: format_errors(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>

    <div class="grid md:grid-cols-2 gap-4 mt-4">
      <.card>
        <:header>New Workspace</:header>
        <form id="workspace-form" phx-submit="create_workspace" class="space-y-3">
          <.input_field name="workspace[name]" label="Name" />
          <.input_field name="workspace[slug]" label="Slug" />
          <.button>Create</.button>
        </form>
      </.card>

      <.card>
        <:header>Existing Workspaces</:header>
        <ul id="workspace-list" class="space-y-1 text-sm">
          <li :for={ws <- @workspaces} id={"ws-#{ws.id}"} class="border-b pb-1">
            <span class="font-semibold">{ws.name}</span>
            <span class="ml-2 text-zinc-500 font-mono text-xs">{ws.slug}</span>
          </li>
        </ul>
        <.empty_state :if={@workspaces == []} title="No workspaces" description="Create your first workspace." icon="folder" />
      </.card>
    </div>

    <.card class="mt-4 max-w-md">
      <:header>New Partition</:header>
      <form id="partition-form" phx-submit="create_partition" class="space-y-3">
        <.select_field name="partition[workspace_id]" label="Workspace">
          <option :for={ws <- @workspaces} value={ws.id}>{ws.name}</option>
        </.select_field>
        <.input_field name="partition[name]" label="Name" />
        <.input_field name="partition[key]" label="Key" />
        <.button>Create Partition</.button>
      </form>
      <p :if={@form_error} class="mt-2 text-red-600 text-xs">{@form_error}</p>
    </.card>

    <.card :if={@partitions != []} class="mt-4">
      <:header>Partitions</:header>
      <ul class="space-y-1 text-sm">
        <li :for={p <- @partitions} class="border-b pb-1">
          <span class="font-semibold">{p.name}</span>
          <span class="ml-2 text-zinc-500 font-mono text-xs">{p.key}</span>
        </li>
      </ul>
    </.card>
    """
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join(", ", fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
  end
end
