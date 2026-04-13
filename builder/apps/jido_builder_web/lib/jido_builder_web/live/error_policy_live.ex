defmodule JidoBuilderWeb.ErrorPolicyLive do
  @moduledoc "Phase Final A.3 — Error Policy editor with circuit breaker status and DLQ viewer."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.{Templates, DeadLetterQueue}
  alias JidoBuilderRuntime.CircuitBreaker

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
       saved?: false,
       breakers: CircuitBreaker.list_all(),
       dlq_entries: DeadLetterQueue.list(workspace_id)
     )}
  end

  @impl true
  def handle_event("save", %{"template_id" => template_id, "policy" => policy}, socket) do
    template = Templates.get_template!(template_id)
    config = Map.put(template.config || %{}, "error_policy", policy)
    {:ok, _} = Templates.update_template(template, %{config: config}, "web")

    {:noreply, assign(socket, selected_template_id: template.id, selected_policy: policy, saved?: true)}
  end

  def handle_event("retry_dlq", %{"entry-id" => entry_id}, socket) do
    {id, ""} = Integer.parse(entry_id)
    {:ok, _} = DeadLetterQueue.retry(id)
    {:noreply, assign(socket, dlq_entries: DeadLetterQueue.list(socket.assigns.workspace_id))}
  end

  def handle_event("purge_dlq", %{"entry-id" => entry_id}, socket) do
    {id, ""} = Integer.parse(entry_id)
    {:ok, _} = DeadLetterQueue.purge(id)
    {:noreply, assign(socket, dlq_entries: DeadLetterQueue.list(socket.assigns.workspace_id))}
  end

  def handle_event("refresh_breakers", _params, socket) do
    {:noreply, assign(socket, breakers: CircuitBreaker.list_all())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>

    <.card class="mt-4 max-w-lg">
      <:header>Error Policy</:header>
      <form id="error-policy-form" phx-submit="save" class="space-y-4">
        <div>
          <label class="block text-xs font-medium mb-1">Template</label>
          <select name="template_id" class="border rounded px-2 py-1 w-full text-sm">
            <option :for={t <- @templates} value={t.id} selected={to_string(@selected_template_id) == to_string(t.id)}>
              {t.name} ({t.slug})
            </option>
          </select>
        </div>

        <fieldset>
          <legend class="text-xs font-medium mb-2">Policy</legend>
          <label :for={policy <- @policies} class="flex items-center gap-2 text-sm py-1">
            <input type="radio" name="policy" value={policy} checked={@selected_policy == policy} />
            {policy}
          </label>
        </fieldset>

        <.button>Save policy</.button>
      </form>
      <p :if={@saved?} id="error-policy-saved" class="mt-4 text-xs text-emerald-700">Error policy saved.</p>
    </.card>

    <%!-- Circuit Breaker Status --%>
    <.card class="mt-6">
      <:header>
        <span class="flex items-center justify-between w-full">
          Circuit Breakers
          <button phx-click="refresh_breakers" class="text-xs text-blue-600 hover:underline">Refresh</button>
        </span>
      </:header>
      <div :if={@breakers == []} class="text-sm text-zinc-500 py-2">No active circuit breakers.</div>
      <table :if={@breakers != []} class="w-full text-sm" id="circuit-breaker-table">
        <thead>
          <tr class="border-b text-left text-xs text-zinc-500">
            <th class="py-1 pr-4">Key</th>
            <th class="py-1 pr-4">Failures</th>
            <th class="py-1">State</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={b <- @breakers} class="border-b last:border-0">
            <td class="py-1 pr-4 font-mono text-xs">{inspect(b.key)}</td>
            <td class="py-1 pr-4">{b.failures}</td>
            <td class={"py-1 font-semibold #{breaker_state_color(b.state)}"}>{b.state}</td>
          </tr>
        </tbody>
      </table>
    </.card>

    <%!-- Dead Letter Queue --%>
    <.card class="mt-6">
      <:header>Dead Letter Queue</:header>
      <div :if={@dlq_entries == []} class="text-sm text-zinc-500 py-2">No dead letter entries.</div>
      <table :if={@dlq_entries != []} class="w-full text-sm" id="dlq-table">
        <thead>
          <tr class="border-b text-left text-xs text-zinc-500">
            <th class="py-1 pr-2">Agent</th>
            <th class="py-1 pr-2">Signal</th>
            <th class="py-1 pr-2">Error</th>
            <th class="py-1 pr-2">Status</th>
            <th class="py-1">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={entry <- @dlq_entries} class="border-b last:border-0">
            <td class="py-1 pr-2 font-mono text-xs">{entry.agent_name}</td>
            <td class="py-1 pr-2 text-xs">{entry.signal_type}</td>
            <td class="py-1 pr-2 text-xs text-red-600 max-w-xs truncate">{entry.error}</td>
            <td class={"py-1 pr-2 text-xs font-semibold #{dlq_status_color(entry.status)}"}>{entry.status}</td>
            <td class="py-1 text-xs space-x-2">
              <button :if={entry.status == "pending"} phx-click="retry_dlq" phx-value-entry-id={entry.id} class="text-blue-600 hover:underline">Retry</button>
              <button :if={entry.status == "pending"} phx-click="purge_dlq" phx-value-entry-id={entry.id} class="text-zinc-400 hover:underline">Purge</button>
            </td>
          </tr>
        </tbody>
      </table>
    </.card>
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

  defp breaker_state_color(:closed), do: "text-emerald-600"
  defp breaker_state_color(:open), do: "text-red-600"
  defp breaker_state_color(:half_open), do: "text-amber-500"
  defp breaker_state_color(_), do: "text-zinc-500"

  defp dlq_status_color("pending"), do: "text-amber-600"
  defp dlq_status_color("retried"), do: "text-blue-600"
  defp dlq_status_color("purged"), do: "text-zinc-400"
  defp dlq_status_color(_), do: "text-zinc-500"
end
