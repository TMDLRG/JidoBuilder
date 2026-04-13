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
       templates: templates,
       selected_template_id: selected && selected.id,
       profiles: config_list(selected, "identity_profiles")
     )}
  end

  @impl true
  def handle_event("select_template", %{"template_id" => id}, socket) do
    tid = case Integer.parse(id) do
      {n, ""} -> n
      _ -> nil
    end

    template = if tid, do: Templates.get_template!(tid)
    {:noreply, assign(socket, selected_template_id: tid, profiles: config_list(template, "identity_profiles"))}
  end

  def handle_event("delete_profile", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    template = Templates.get_template!(socket.assigns.selected_template_id)
    profiles = config_list(template, "identity_profiles") |> List.delete_at(idx)
    {:ok, updated} = Templates.update_template(template, %{config: Map.put(template.config || %{}, "identity_profiles", profiles)}, "web")
    {:noreply, assign(socket, profiles: config_list(updated, "identity_profiles"))}
  end

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
    <.page_header>{@page_title}</.page_header>

    <div :if={length(@templates) > 1} class="mb-4">
      <label class="text-xs font-medium text-zinc-600">Template</label>
      <form phx-change="select_template" class="mt-1">
        <select name="template_id" class="ui-input text-sm">
          <option :for={t <- @templates} value={t.id} selected={t.id == @selected_template_id}>{t.name}</option>
        </select>
      </form>
    </div>

    <.card class="max-w-md mb-4">
      <:header>New Identity Profile</:header>
      <form id="identity-form" phx-submit="create" class="space-y-2">
        <.input_field name="profile[name]" label="Name" placeholder="Name" />
        <.input_field name="profile[persona]" label="Persona" placeholder="Persona" />
        <.input_field name="profile[capabilities]" label="Capabilities" placeholder="Capabilities" />
        <.button>Create profile</.button>
      </form>
    </.card>

    <.card>
      <:header>Identity Profiles</:header>
      <ul id="identity-profiles-list" class="space-y-2 text-sm">
        <li :for={{profile, idx} <- Enum.with_index(@profiles)} class="rounded border p-2 flex justify-between items-start">
          <div>
            <p class="font-semibold">{profile["name"]}</p>
            <p class="text-xs text-zinc-600">{profile["persona"]}</p>
            <p class="text-xs text-zinc-400">{profile["capabilities"]}</p>
          </div>
          <button phx-click="delete_profile" phx-value-index={idx} class="text-xs text-red-500 hover:text-red-700 shrink-0">Delete</button>
        </li>
      </ul>
      <.empty_state :if={@profiles == []} title="No profiles" description="No identity profiles configured yet." icon="user" />
    </.card>
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
