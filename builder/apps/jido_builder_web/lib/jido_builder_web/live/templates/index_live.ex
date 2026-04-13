defmodule JidoBuilderWeb.Templates.IndexLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Templates

  @impl true
  def mount(params, _session, socket) do
    workspace_id = workspace_id_from_params(params)
    templates = Templates.list_templates(workspace_id)

    {:ok,
     socket
     |> assign(page_title: "Templates", workspace_id: workspace_id, empty: templates == [])
     |> stream(:templates, templates)}
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>

    <.card class="mt-4">
      <:header>Templates</:header>
      <div id="templates-list" phx-update="stream">
        <div
          :for={{dom_id, tmpl} <- @streams.templates}
          id={dom_id}
          class="flex items-center justify-between border-b py-2 text-sm"
        >
          <div>
            <span class="font-semibold">{tmpl.name}</span>
            <span class="ml-2 text-zinc-500 font-mono text-xs">{tmpl.slug}</span>
            <.badge variant={if tmpl.status == "active", do: "success", else: "default"}>{tmpl.status}</.badge>
          </div>
          <.link navigate={~p"/templates/#{tmpl.id}/edit"} class="text-xs text-blue-600 hover:underline">Edit</.link>
        </div>
      </div>
      <.empty_state :if={@empty} title="No templates" description="No templates created yet." icon="folder" />
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
