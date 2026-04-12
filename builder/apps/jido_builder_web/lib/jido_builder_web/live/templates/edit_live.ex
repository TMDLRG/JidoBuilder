defmodule JidoBuilderWeb.Templates.EditLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Templates
  alias JidoBuilderCore.Templates.Template

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    template = Templates.get_template!(id)

    {:ok,
     socket
     |> assign(
       page_title: "Edit Template",
       template: template,
       changeset: Template.changeset(template, %{}),
       saved: false
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_event("save", %{"template" => params}, socket) do
    template = socket.assigns.template
    actor = socket.assigns.current_user.email

    case Templates.update_template(template, params, actor) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(
           template: updated,
           changeset: Template.changeset(updated, %{}),
           saved: true
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset, saved: false)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <form id="template-form" phx-submit="save" class="space-y-4 max-w-lg">
      <div>
        <label class="block text-sm font-medium mb-1">Name</label>
        <input
          type="text"
          name="template[name]"
          value={@template.name}
          class="border rounded px-2 py-1 w-full text-sm"
        />
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Slug</label>
        <input
          type="text"
          name="template[slug]"
          value={@template.slug}
          class="border rounded px-2 py-1 w-full text-sm"
          readonly
        />
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Description</label>
        <textarea
          name="template[description]"
          rows="3"
          class="border rounded px-2 py-1 w-full text-sm"
        ><%= @template.description %></textarea>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Status</label>
        <select name="template[status]" class="border rounded px-2 py-1 w-full text-sm">
          <option value="draft" selected={@template.status == "draft"}>Draft</option>
          <option value="active" selected={@template.status == "active"}>Active</option>
          <option value="archived" selected={@template.status == "archived"}>Archived</option>
        </select>
      </div>

      <button type="submit" class="rounded bg-zinc-900 px-4 py-2 text-white text-sm">
        Save
      </button>

      <p :if={@saved} class="text-sm text-green-600">Saved.</p>
    </form>

    <p class="mt-6 text-xs text-zinc-400">
      Template: <%= @template.name %> (v<%= @template.version %>)
    </p>
    """
  end
end
