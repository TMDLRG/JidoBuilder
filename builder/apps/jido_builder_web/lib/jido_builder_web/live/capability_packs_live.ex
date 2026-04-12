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
    <.page_header><%= @page_title %></.page_header>

    <section class="mt-6">
      <h2 class="text-sm font-semibold text-zinc-700 mb-2">Discovered Plugins</h2>
      <ul class="space-y-1 text-sm">
        <li :for={plugin <- @discovered} class="border-b pb-1">
          <span class="font-mono"><%= inspect(plugin) %></span>
        </li>
      </ul>
      <p :if={@discovered == []} class="text-sm text-zinc-500">
        No plugins registered in discovery yet.
      </p>
    </section>

    <section class="mt-6">
      <h2 class="text-sm font-semibold text-zinc-700 mb-2">Configured Plugins</h2>
      <ul id="plugin-list" class="space-y-2 text-sm">
        <li :for={plugin <- @plugins} id={"plugin-#{plugin.id}"} class="flex items-center gap-4 border-b pb-2">
          <span class="font-semibold"><%= plugin.name %></span>
          <span class="font-mono text-xs text-zinc-500"><%= plugin.module %></span>
          <span class={if plugin.enabled, do: "text-green-600", else: "text-zinc-400 line-through"}>
            <%= if plugin.enabled, do: "enabled", else: "disabled" %>
          </span>
          <button
            :if={plugin.enabled}
            phx-click="disable_plugin"
            phx-value-id={plugin.id}
            class="text-xs text-red-600 hover:underline"
          >
            Disable
          </button>
          <button
            :if={not plugin.enabled}
            phx-click="enable_plugin"
            phx-value-id={plugin.id}
            class="text-xs text-green-600 hover:underline"
          >
            Enable
          </button>
        </li>
      </ul>
      <p :if={@plugins == []} class="text-sm text-zinc-500">
        No plugins configured for this workspace.
      </p>
    </section>
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
