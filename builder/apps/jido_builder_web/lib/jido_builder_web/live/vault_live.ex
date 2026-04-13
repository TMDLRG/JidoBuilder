defmodule JidoBuilderWeb.VaultLive do
  @moduledoc "Phase 4 — Vault: hibernate/thaw agent snapshots."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Agents

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)
    snapshots = Agents.list_snapshots(workspace_id)

    {:ok, assign(socket, page_title: "Vault", workspace_id: workspace_id, snapshots: snapshots)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>
    <p class="text-sm text-zinc-500 mb-4">Hibernate and thaw agent snapshots.</p>
    <ul id="snapshot-list" class="space-y-2 text-sm">
      <li :for={snap <- @snapshots} id={"snap-#{snap.id}"} class="border-b pb-2">
        <span class="font-semibold">{snap.metadata["label"] || "snapshot-#{snap.id}"}</span>
        <span :if={snap.agent_instance} class="ml-2 text-zinc-500">agent: {snap.agent_instance.name}</span>
        <span class="ml-2 text-zinc-400 text-xs">{snap.captured_at}</span>
      </li>
    </ul>
    <p :if={@snapshots == []} class="text-sm text-zinc-500 mt-4">No snapshots.</p>
    """
  end

  defp wid(%{"workspace_id" => id}) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end
  defp wid(_), do: 1
end
