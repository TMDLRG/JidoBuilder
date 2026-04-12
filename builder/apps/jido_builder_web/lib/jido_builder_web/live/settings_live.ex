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
      <.empty_state :if={@integrations == []} title="No integrations" description="No integrations configured." icon="bolt" />
    </.card>

    <.card class="mt-6"><:header>Secrets</:header>
      <ul class="space-y-1 text-sm">
        <li :for={secret <- @secrets} class="border-b pb-1">
          <span class="font-semibold"><%= secret.name %></span>
          <span class="ml-2 text-zinc-400 text-xs font-mono">{secret.value}</span>
        </li>
      </ul>
      <.empty_state :if={@secrets == []} title="No secrets" description="No secrets stored." icon="cog" />
    </.card>

    <.card class="mt-6 max-w-md"><:header>Add Secret</:header>
      <form id="secret-form" phx-submit="create_secret" class="space-y-3">
        <.input_field name="secret[name]" label="Name" placeholder="API_KEY" />
        <.input_field name="secret[value]" label="Value" type="password" />
        <.button>Save Secret</.button>
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
