defmodule JidoBuilderWeb.OrphansLive do
  @moduledoc "Phase Final A.4 — Orphans list and adoption flow."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Pods

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)

    {:ok,
     assign(socket,
       page_title: "Orphan Agents",
       workspace_id: workspace_id,
       orphans: list_orphans(workspace_id),
       topologies: Pods.list_topologies(workspace_id),
       adopted?: false
     )}
  end

  @impl true
  def handle_event("adopt", %{"agent_id" => agent_id, "pod_topology_id" => topology_id}, socket) do
    agent = Enum.find(socket.assigns.orphans, &(to_string(&1.id) == agent_id))

    {:ok, _node} =
      Pods.create_node(
        %{
          pod_topology_id: String.to_integer(topology_id),
          agent_instance_id: String.to_integer(agent_id),
          name: "adopted-#{agent.name}",
          role: "worker",
          position: 0,
          metadata: %{"source" => "orphans_live"}
        },
        "web"
      )

    {:noreply,
     assign(socket,
       orphans: list_orphans(socket.assigns.workspace_id),
       adopted?: true
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p class="text-sm text-zinc-500 mb-4">Agents not attached to any pod topology.</p>

    <.card class="mt-4">
      <:header>Orphan Agents</:header>
      <div :for={agent <- @orphans} class="rounded border p-3 mb-2 text-sm">
        <p class="font-semibold">{agent.name}</p>
        <form id={"adopt-form-#{agent.id}"} phx-submit="adopt" class="mt-2 flex gap-2 items-center">
          <input type="hidden" name="agent_id" value={agent.id} />
          <select name="pod_topology_id" class="border rounded px-2 py-1 text-xs">
            <option :for={t <- @topologies} value={t.id}>{t.name}</option>
          </select>
          <.button>Adopt</.button>
        </form>
      </div>
      <.empty_state :if={@orphans == []} title="No orphan agents" description="All agents are attached to a pod." icon="users" />
      <p :if={@adopted?} id="orphans-adopted" class="text-xs text-emerald-700 mt-2">Agent adopted into topology.</p>
    </.card>
    """
  end

  defp list_orphans(workspace_id) do
    import Ecto.Query
    alias JidoBuilderCore.{Agents.AgentInstance, Pods.PodNode, Repo}

    attached_ids =
      PodNode
      |> where([n], not is_nil(n.agent_instance_id))
      |> select([n], n.agent_instance_id)
      |> Repo.all()

    AgentInstance
    |> where([a], a.workspace_id == ^workspace_id)
    |> where([a], a.id not in ^attached_ids)
    |> Repo.all()
  end

  defp wid(%{"workspace_id" => id}) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end
  defp wid(_), do: 1
end
