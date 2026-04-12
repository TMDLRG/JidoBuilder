defmodule JidoBuilderWeb.OrphansLive do
  @moduledoc "Phase 6 — Orphans + Adoption view."
  use JidoBuilderWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)

    # Orphan agents = running instances not attached to any pod node
    orphans = list_orphans(workspace_id)

    {:ok, assign(socket, page_title: "Orphan Agents", workspace_id: workspace_id, orphans: orphans)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p class="text-sm text-zinc-500 mb-4">Agents not attached to any pod topology.</p>
    <ul class="space-y-1 text-sm">
      <li :for={agent <- @orphans} class="border-b pb-1">
        <span class="font-semibold"><%= agent.name %></span>
        <span class="ml-2 text-zinc-400 text-xs">status: <%= agent.status %></span>
      </li>
    </ul>
    <p :if={@orphans == []} class="text-sm text-zinc-500 mt-4">No orphan agents found.</p>
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
