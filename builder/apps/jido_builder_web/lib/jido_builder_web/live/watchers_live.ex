defmodule JidoBuilderWeb.WatchersLive do
  @moduledoc """
  Phase 3.2 — Watchers: sensor browser + configurator.

  Shows discovered sensors (Jido.Discovery) alongside persisted
  template-sensor rows for the workspace.  Operators can toggle enabled.
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
      case Discovery.list_sensors(context) do
        {:ok, list} -> list
        _ -> []
      end

    sensors = Templates.list_template_sensors(workspace_id)

    {:ok,
     assign(socket,
       page_title: "Watchers",
       workspace_id: workspace_id,
       discovered: discovered,
       sensors: sensors
     )}
  end

  @impl true
  def handle_event("disable_sensor", %{"id" => id}, socket) do
    sensor = Repo.get!(JidoBuilderCore.Templates.TemplateSensor, id)
    user = socket.assigns.current_user
    {:ok, _} = Templates.update_sensor(sensor, %{enabled: false}, user.email)
    sensors = Templates.list_template_sensors(socket.assigns.workspace_id)
    {:noreply, assign(socket, sensors: sensors)}
  end

  @impl true
  def handle_event("enable_sensor", %{"id" => id}, socket) do
    sensor = Repo.get!(JidoBuilderCore.Templates.TemplateSensor, id)
    user = socket.assigns.current_user
    {:ok, _} = Templates.update_sensor(sensor, %{enabled: true}, user.email)
    sensors = Templates.list_template_sensors(socket.assigns.workspace_id)
    {:noreply, assign(socket, sensors: sensors)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <section class="mt-6">
      <h2 class="text-sm font-semibold text-zinc-700 mb-2">Discovered Sensors</h2>
      <ul class="space-y-1 text-sm">
        <li :for={sensor <- @discovered} class="border-b pb-1">
          <span class="font-mono"><%= inspect(sensor) %></span>
        </li>
      </ul>
      <p :if={@discovered == []} class="text-sm text-zinc-500">
        No sensors registered in discovery yet.
      </p>
    </section>

    <section class="mt-6">
      <h2 class="text-sm font-semibold text-zinc-700 mb-2">Configured Watchers</h2>
      <ul id="sensor-list" class="space-y-2 text-sm">
        <li :for={sensor <- @sensors} id={"sensor-#{sensor.id}"} class="flex items-center gap-4 border-b pb-2">
          <span class="font-semibold"><%= sensor.name %></span>
          <span class="font-mono text-xs text-zinc-500"><%= sensor.module %></span>
          <span class={if sensor.enabled, do: "text-green-600", else: "text-zinc-400 line-through"}>
            <%= if sensor.enabled, do: "enabled", else: "disabled" %>
          </span>
          <button
            :if={sensor.enabled}
            phx-click="disable_sensor"
            phx-value-id={sensor.id}
            class="text-xs text-red-600 hover:underline"
          >
            Disable
          </button>
          <button
            :if={not sensor.enabled}
            phx-click="enable_sensor"
            phx-value-id={sensor.id}
            class="text-xs text-green-600 hover:underline"
          >
            Enable
          </button>
        </li>
      </ul>
      <p :if={@sensors == []} class="text-sm text-zinc-500">
        No watchers configured for this workspace.
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
