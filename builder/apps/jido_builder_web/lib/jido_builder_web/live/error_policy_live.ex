defmodule JidoBuilderWeb.ErrorPolicyLive do
  @moduledoc "Phase Final A.3 — Error Policy editor persisted in template config."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Templates

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)
    templates = Templates.list_templates(workspace_id)
    selected = List.first(templates)

    {:ok,
     assign(socket,
       page_title: "Error Policy",
       workspace_id: workspace_id,
       templates: templates,
       selected_template_id: selected && selected.id,
       selected_policy: policy_from(selected),
       policies: ~w(stop_on_error retry_once ignore escalate),
       saved?: false
     )}
  end

  @impl true
  def handle_event("save", %{"template_id" => template_id, "policy" => policy}, socket) do
    template = Templates.get_template!(template_id)
    config = Map.put(template.config || %{}, "error_policy", policy)
    {:ok, _} = Templates.update_template(template, %{config: config}, "web")

    {:noreply, assign(socket, selected_template_id: template.id, selected_policy: policy, saved?: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <form id="error-policy-form" phx-submit="save" class="space-y-4 max-w-lg">
      <div>
        <label class="block text-xs font-medium mb-1">Template</label>
        <select name="template_id" class="border rounded px-2 py-1 w-full text-sm">
          <option :for={t <- @templates} value={t.id} selected={to_string(@selected_template_id) == to_string(t.id)}>
            <%= t.name %> (<%= t.slug %>)
          </option>
        </select>
      </div>

      <fieldset>
        <legend class="text-xs font-medium mb-2">Policy</legend>
        <label :for={policy <- @policies} class="flex items-center gap-2 text-sm py-1">
          <input type="radio" name="policy" value={policy} checked={@selected_policy == policy} />
          <%= policy %>
        </label>
      </fieldset>

      <button type="submit" class="rounded bg-zinc-900 px-4 py-2 text-white text-xs">Save policy</button>
    </form>

    <p :if={@saved?} id="error-policy-saved" class="mt-4 text-xs text-emerald-700">Error policy saved.</p>
    """
  end

  defp policy_from(nil), do: "stop_on_error"
  defp policy_from(template), do: get_in(template.config || %{}, ["error_policy"]) || "stop_on_error"

  defp wid(%{"workspace_id" => id}) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end

  defp wid(_), do: 1
end
