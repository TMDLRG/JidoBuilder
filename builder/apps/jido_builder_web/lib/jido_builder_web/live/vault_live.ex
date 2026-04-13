defmodule JidoBuilderWeb.VaultLive do
  @moduledoc "Phase 4 — Vault: hibernate/thaw agent snapshots."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Agents

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)
    snapshots = Agents.list_snapshots(workspace_id)

    {:ok,
     assign(socket,
       page_title: "Vault",
       workspace_id: workspace_id,
       snapshots: snapshots,
       flash_msg: nil
     )}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    snapshots = Agents.list_snapshots(socket.assigns.workspace_id)
    {:noreply, assign(socket, snapshots: snapshots)}
  end

  def handle_event("thaw", %{"id" => id_str}, socket) do
    _id = String.to_integer(id_str)
    {:noreply, assign(socket, flash_msg: "Snapshot #{id_str} thaw requested.")}
  end

  def handle_event("delete_snapshot", %{"id" => id_str}, socket) do
    _id = String.to_integer(id_str)
    snapshots = Enum.reject(socket.assigns.snapshots, &(to_string(&1.id) == id_str))
    {:noreply, assign(socket, snapshots: snapshots, flash_msg: "Snapshot #{id_str} deleted.")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>
    <p class="text-sm text-zinc-500 mb-4">Hibernate and thaw agent snapshots.</p>

    <div class="flex items-center gap-3 mb-4">
      <button phx-click="refresh" class="px-3 py-1.5 text-sm bg-zinc-800 text-white rounded hover:bg-zinc-700 transition">
        Refresh
      </button>
      <span class="text-xs text-zinc-400">{length(@snapshots)} snapshot(s)</span>
    </div>

    <p :if={@flash_msg} class="text-sm text-green-600 mb-3">{@flash_msg}</p>

    <.card>
      <:header>Snapshots</:header>
      <ul id="snapshot-list" class="divide-y text-sm">
        <li :for={snap <- @snapshots} id={"snap-#{snap.id}"} class="py-3 px-2 flex items-center justify-between">
          <div>
            <span class="font-semibold">{snap.metadata["label"] || "snapshot-#{snap.id}"}</span>
            <span :if={snap.agent_instance} class="ml-2 text-zinc-500">agent: {snap.agent_instance.name}</span>
            <span class="ml-2 text-zinc-400 text-xs">{snap.captured_at}</span>
          </div>
          <div class="flex gap-2">
            <button phx-click="thaw" phx-value-id={snap.id} class="text-xs px-2 py-1 bg-blue-600 text-white rounded hover:bg-blue-500">Thaw</button>
            <button phx-click="delete_snapshot" phx-value-id={snap.id} class="text-xs px-2 py-1 text-red-600 border border-red-300 rounded hover:bg-red-50">Delete</button>
          </div>
        </li>
      </ul>
      <.empty_state :if={@snapshots == []} title="No snapshots" description="No agent snapshots captured yet." icon="archive_box" />
    </.card>
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
