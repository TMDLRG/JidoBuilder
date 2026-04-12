defmodule JidoBuilderWeb.IdentityLive do
  @moduledoc "Phase Final A.11 — Identity profile CRUD-lite."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Templates

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)
    templates = Templates.list_templates(workspace_id)
    selected = List.first(templates)

    {:ok,
     assign(socket,
       page_title: "Identity Profiles",
       selected_template_id: selected && selected.id,
       profiles: config_list(selected, "identity_profiles")
     )}
  end

  @impl true
  def handle_event("create", %{"profile" => attrs}, socket) do
    template = Templates.get_template!(socket.assigns.selected_template_id)

    profile = %{
      "name" => attrs["name"],
      "persona" => attrs["persona"],
      "capabilities" => attrs["capabilities"]
    }

    profiles = config_list(template, "identity_profiles") ++ [profile]
    {:ok, updated} = Templates.update_template(template, %{config: Map.put(template.config || %{}, "identity_profiles", profiles)}, "web")
    {:noreply, assign(socket, profiles: config_list(updated, "identity_profiles"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <form id="identity-form" phx-submit="create" class="max-w-xl grid gap-2">
      <input type="text" name="profile[name]" placeholder="Name" class="border rounded px-2 py-1 text-sm" />
      <input type="text" name="profile[persona]" placeholder="Persona" class="border rounded px-2 py-1 text-sm" />
      <input type="text" name="profile[capabilities]" placeholder="Capabilities" class="border rounded px-2 py-1 text-sm" />
      <button type="submit" class="justify-self-start rounded bg-zinc-900 px-3 py-1 text-white text-xs">Create profile</button>
    </form>

    <ul id="identity-profiles-list" class="mt-4 space-y-2 text-sm">
      <li :for={profile <- @profiles} class="rounded border p-2">
        <p class="font-semibold"><%= profile["name"] %></p>
        <p class="text-xs text-zinc-600"><%= profile["persona"] %></p>
      </li>
    </ul>
    <p :if={@profiles == []} class="text-sm text-zinc-500">No identity profiles configured yet.</p>
    """
  end

  defp config_list(nil, _key), do: []
  defp config_list(template, key), do: get_in(template.config || %{}, [key]) || []

  defp wid(%{"workspace_id" => id}) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end
  defp wid(_), do: 1
end
