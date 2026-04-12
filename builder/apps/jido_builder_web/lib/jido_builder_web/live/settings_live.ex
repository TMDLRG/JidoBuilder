defmodule JidoBuilderWeb.SettingsLive do
  @moduledoc "Phase 4 — Settings/Integrations/Secrets."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Security

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)
    integrations = Security.list_integrations(workspace_id)
    secrets = Security.list_secrets_for_ui(%{workspace_id: workspace_id})

    {:ok,
     assign(socket,
       page_title: "Settings",
       workspace_id: workspace_id,
       integrations: integrations,
       secrets: secrets,
       form_error: nil, toast: nil
     )}
  end

  @impl true
  def handle_event("create_secret", %{"secret" => attrs}, socket) do
    workspace_id = socket.assigns.workspace_id
    user = socket.assigns.current_user
    merged = Map.put(attrs, "workspace_id", workspace_id)

    case Security.write_secret(atomize(merged), user.email) do
      {:ok, _} ->
        secrets = Security.list_secrets_for_ui(%{workspace_id: workspace_id})
        {:noreply, assign(socket, secrets: secrets, form_error: nil, toast: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, form_error: inspect(changeset.errors))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <.toast :if={@toast} title={@toast.title} message={@toast.message} variant="info" />

    <.card class="mt-6"><:header>Integrations</:header>
      <h2 class="text-sm font-semibold mb-2">Integrations</h2>
      <ul class="space-y-1 text-sm">
        <li :for={integ <- @integrations} class="border-b pb-1">
          <span class="font-semibold"><%= integ.name %></span>
          <span class="ml-2 text-zinc-500"><%= integ.provider %></span>
          <span class="ml-2 text-xs text-zinc-400"><%= integ.status %></span>
        </li>
      </ul>
      <p :if={@integrations == []} class="text-sm text-zinc-500">No integrations.</p>
    </.card>

    <.card class="mt-6"><:header>Secrets</:header>
      <h2 class="text-sm font-semibold mb-2">Secrets</h2>
      <ul class="space-y-1 text-sm">
        <li :for={secret <- @secrets} class="border-b pb-1">
          <span class="font-semibold"><%= secret.name %></span>
          <span class="ml-2 text-zinc-400 text-xs"><%= secret.value %></span>
        </li>
      </ul>
      <p :if={@secrets == []} class="text-sm text-zinc-500">No secrets.</p>
    </.card>

    <.card class="mt-6 max-w-md"><:header>Add Secret</:header>
      <h2 class="text-sm font-semibold mb-2">Add Secret</h2>
      <form id="secret-form" phx-submit="create_secret" class="space-y-3">
        <div>
          <label class="block text-xs font-medium mb-1">Name</label>
          <input type="text" name="secret[name]" placeholder="API_KEY" class="border rounded px-2 py-1 w-full text-sm" />
        </div>
        <div>
          <label class="block text-xs font-medium mb-1">Value</label>
          <input type="password" name="secret[value]" class="border rounded px-2 py-1 w-full text-sm" />
        </div>
        <button type="submit" class="rounded bg-zinc-900 px-4 py-2 text-white text-xs">
          Save Secret
        </button>
      </form>
      <p :if={@form_error} class="mt-2 text-red-600 text-xs"><%= @form_error %></p>
    </.card>
    """
  end

  defp atomize(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_atom(k), v}
      {k, v} -> {k, v}
    end)
  end

  defp wid(%{"workspace_id" => id}) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end
  defp wid(_), do: 1
end
