defmodule JidoBuilderWeb.CapabilityPacksLive do
  @moduledoc """
  Phase 3.1 — Capability Packs: plugin browser + edit.

  Displays discovered plugins (from Jido.Discovery) alongside persisted
  template-plugin rows for the current workspace.  Operators can toggle a
  plugin's enabled flag inline.
  """
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.{Repo, Templates}
  alias JidoBuilderRuntime.Discovery

  @impl true
  def mount(params, _session, socket) do
    workspace_id = workspace_id_from_params(params)
    user = socket.assigns.current_user
    context = %{workspace_id: workspace_id, actor: user.email}

    discovered =
      case Discovery.list_plugins(context) do
        {:ok, list} -> list
        _ -> []
      end

    plugins = Templates.list_template_plugins(workspace_id)

    {:ok,
     assign(socket,
       page_title: "Capability Packs",
       workspace_id: workspace_id,
       discovered: discovered,
       plugins: plugins
     )}
  end

  @impl true
  def handle_event("disable_plugin", %{"id" => id}, socket) do
    plugin = Repo.get!(JidoBuilderCore.Templates.TemplatePlugin, id)
    user = socket.assigns.current_user

    {:ok, _} = Templates.update_plugin(plugin, %{enabled: false}, user.email)

    plugins = Templates.list_template_plugins(socket.assigns.workspace_id)
    {:noreply, assign(socket, plugins: plugins)}
  end

  @impl true
  def handle_event("enable_plugin", %{"id" => id}, socket) do
    plugin = Repo.get!(JidoBuilderCore.Templates.TemplatePlugin, id)
    user = socket.assigns.current_user

    {:ok, _} = Templates.update_plugin(plugin, %{enabled: true}, user.email)

    plugins = Templates.list_template_plugins(socket.assigns.workspace_id)
    {:noreply, assign(socket, plugins: plugins)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>

    <div class="grid md:grid-cols-2 gap-4 mt-6">
      <.card>
        <:header>Discovered Plugins</:header>
        <ul class="space-y-1 text-sm">
          <li :for={plugin <- @discovered} class="border-b pb-1"><span class="font-mono text-xs">{inspect(plugin)}</span></li>
        </ul>
        <.empty_state :if={@discovered == []} title="No plugins" description="No plugins in discovery." icon="bolt" />
      </.card>

      <.card>
        <:header>Configured Plugins</:header>
        <ul id="plugin-list" class="space-y-2 text-sm">
          <li :for={plugin <- @plugins} id={"plugin-#{plugin.id}"} class="flex items-center gap-2 border-b pb-2">
            <span class="font-semibold flex-1">{plugin.name}</span>
            <.badge variant={if plugin.enabled, do: "success", else: "default"}>{if plugin.enabled, do: "enabled", else: "disabled"}</.badge>
            <button :if={plugin.enabled} phx-click="disable_plugin" phx-value-id={plugin.id} class="text-xs text-red-600 hover:underline">Disable</button>
            <button :if={not plugin.enabled} phx-click="enable_plugin" phx-value-id={plugin.id} class="text-xs text-green-600 hover:underline">Enable</button>
          </li>
        </ul>
        <.empty_state :if={@plugins == []} title="No plugins configured" description="No plugins for this workspace." icon="bolt" />
      </.card>
    </div>
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
