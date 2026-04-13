defmodule JidoBuilderWeb.HierarchyLive do
  @moduledoc """
  Phase 3.4 — Hierarchy view: parent/child agent relationships.

  Shows pod topologies with their member nodes and linked agent instances.
  Operators can add a node (link an agent to a pod).
  """
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Pods

  @impl true
  def mount(params, _session, socket) do
    workspace_id = workspace_id_from_params(params)
    topologies = Pods.list_topologies_with_nodes(workspace_id)
    instances = list_instances(workspace_id)

    {:ok,
     assign(socket,
       page_title: "Hierarchy",
       workspace_id: workspace_id,
       topologies: topologies,
       instances: instances,
       form_error: nil
     )}
  end

  @impl true
  def handle_event("add_node", %{"node" => attrs}, socket) do
    workspace_id = socket.assigns.workspace_id
    user = socket.assigns.current_user

    case Pods.create_node(attrs, user.email) do
      {:ok, _node} ->
        topologies = Pods.list_topologies_with_nodes(workspace_id)
        {:noreply, assign(socket, topologies: topologies, form_error: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, form_error: inspect(changeset.errors))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>
    <p class="text-sm text-zinc-500 mb-4">Agent parent/child relationships via pod topology.</p>

    <section class="mt-4 max-w-lg">
      <h2 class="text-sm font-semibold mb-2">Add Node to Pod</h2>
      <form id="add-node-form" phx-submit="add_node" class="space-y-3">
        <div>
          <label class="block text-xs font-medium mb-1">Pod (Topology)</label>
          <select name="node[pod_topology_id]" class="border rounded px-2 py-1 w-full text-sm">
            <option value="">— select —</option>
            <option :for={topo <- @topologies} value={topo.id}>{topo.name}</option>
          </select>
        </div>
        <div>
          <label class="block text-xs font-medium mb-1">Agent Instance</label>
          <select name="node[agent_instance_id]" class="border rounded px-2 py-1 w-full text-sm">
            <option value="">— select —</option>
            <option :for={inst <- @instances} value={inst.id}>{inst.name}</option>
          </select>
        </div>
        <div>
          <label class="block text-xs font-medium mb-1">Node Name</label>
          <input type="text" name="node[name]" placeholder="child-1" class="border rounded px-2 py-1 w-full text-sm" />
        </div>
        <div class="flex gap-3">
          <div class="flex-1">
            <label class="block text-xs font-medium mb-1">Role</label>
            <select name="node[role]" class="border rounded px-2 py-1 w-full text-sm">
              <option value="worker">Worker</option>
              <option value="coordinator">Coordinator</option>
              <option value="observer">Observer</option>
            </select>
          </div>
          <div class="w-20">
            <label class="block text-xs font-medium mb-1">Position</label>
            <input type="number" name="node[position]" value="1" min="1" class="border rounded px-2 py-1 w-full text-sm" />
          </div>
        </div>
        <.button>Add Node</.button>
      </form>
      <p :if={@form_error} class="mt-2 text-red-600 text-xs">{@form_error}</p>
    </section>

    <section class="mt-8">
      <h2 class="text-sm font-semibold mb-3">Pod Topology Tree</h2>
      <.empty_state :if={@topologies == []} title="No topologies" description="No pod topologies in this workspace." icon="users" />
      <div :for={topo <- @topologies} id={"topo-#{topo.id}"} class="mb-6 border rounded p-3">
        <h3 class="font-semibold text-sm mb-2">
          <span>{topo.name}</span>
          <span class="ml-2 text-xs text-zinc-400">strategy: {topo.strategy}</span>
        </h3>
        <ul class="pl-4 space-y-1 text-xs">
          <li :for={node <- topo.nodes} id={"node-#{node.id}"} class="flex items-center gap-2">
            <span class="font-medium">{node.name}</span>
            <span class="text-zinc-400">role: {node.role}</span>
            <span :if={node.agent_instance} class="text-zinc-600">
              → {node.agent_instance.name}
            </span>
          </li>
          <li :if={topo.nodes == []} class="text-zinc-400 italic">No nodes yet.</li>
        </ul>
      </div>
    </section>
    """
  end

  defp list_instances(workspace_id) do
    import Ecto.Query
    alias JidoBuilderCore.{Agents.AgentInstance, Repo}

    AgentInstance
    |> where([a], a.workspace_id == ^workspace_id)
    |> Repo.all()
  end

  defp workspace_id_from_params(%{"workspace_id" => id}) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end

  defp workspace_id_from_params(_), do: 1
end
