defmodule JidoBuilderWeb.TeamsLive do
  @moduledoc """
  Phase 3.3 — Teams / Pods MVP.

  Lists pod topologies for the workspace and lets operators create new ones.
  Uses `JidoBuilderCore.Pods` for DB CRUD and `JidoBuilderRuntime.PodRuntime`
  for booting a pod from a template (reflected in UI status).
  """
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Pods

  @impl true
  def mount(params, _session, socket) do
    workspace_id = workspace_id_from_params(params)
    topologies = Pods.list_topologies(workspace_id)

    {:ok,
     assign(socket,
       page_title: "Teams (Pods)",
       workspace_id: workspace_id,
       topologies: topologies,
       form_error: nil, toast: nil
     )}
  end

  @impl true
  def handle_event("create_topology", %{"topology" => attrs}, socket) do
    workspace_id = socket.assigns.workspace_id
    user = socket.assigns.current_user

    merged =
      attrs
      |> Map.put("workspace_id", workspace_id)

    case Pods.create_topology(merged, user.email) do
      {:ok, _topo} ->
        topologies = Pods.list_topologies(workspace_id)
        {:noreply, assign(socket, topologies: topologies, form_error: nil, toast: nil)}

      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Enum.reduce(opts, msg, fn {key, value}, acc -> String.replace(acc, "%{#{key}}", to_string(value)) end)
        end) |> Enum.map_join(", ", fn {field, errs} -> "#{field}: #{Enum.join(errs, ", ")}" end)
        {:noreply, assign(socket, form_error: errors)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <.toast :if={@toast} title={@toast.title} message={@toast.message} variant="info" />
    <p class="text-sm text-zinc-500 mb-4">Coordinate pods of specialized agents.</p>

    <.card class="mt-4 max-w-md"><:header>New Team / Pod</:header>
      <h2 class="text-sm font-semibold mb-2">New Team / Pod</h2>
      <form id="topology-form" phx-submit="create_topology" class="space-y-3">
        <.input_field name="topology[name]" label="Name" placeholder="AlphaTeam" />
        <.select_field name="topology[strategy]" label="Strategy">
          <option value="round_robin">Round Robin</option>
          <option value="broadcast">Broadcast</option>
          <option value="random">Random</option>
        </.select_field>
        <.button>Create Pod</.button>
      </form>
      <p :if={@form_error} class="mt-2 text-red-600 text-xs"><%= @form_error %></p>
    </.card>

    <.card class="mt-8"><:header>Existing Pods</:header>
      <ul id="topology-list" class="space-y-2 text-sm">
        <li :for={topo <- @topologies} id={"topo-#{topo.id}"} class="border-b pb-2">
          <span class="font-semibold"><%= topo.name %></span>
          <.badge variant="default"><%= topo.strategy %></.badge>
        </li>
      </ul>
      <.empty_state :if={@topologies == []} title="No pods" description="No pods configured for this workspace." icon="users" />
    </.card>
    """
  end

  defp workspace_id_from_params(%{"workspace_id" => id}) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end

  defp workspace_id_from_params(_), do: 1
end
