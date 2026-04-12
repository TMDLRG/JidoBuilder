defmodule JidoBuilderWeb.DebugLive do
  @moduledoc "Phase 6 — Debug panel: live ring buffer via telemetry."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Observability

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)
    errors = Observability.list_recent_errors(workspace_id, limit: 20)
    traces = Observability.list_recent_traces(workspace_id, limit: 20)

    {:ok,
     assign(socket,
       page_title: "Debug",
       workspace_id: workspace_id,
       errors: errors,
       traces: traces
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <section class="mt-4">
      <h2 class="text-sm font-semibold mb-2">Recent Errors</h2>
      <ul class="space-y-1 text-xs font-mono">
        <li :for={e <- @errors} class="border-b pb-1 text-red-700"><%= e.directive_type %>: <%= e.status %></li>
      </ul>
      <p :if={@errors == []} class="text-sm text-zinc-500">No recent errors.</p>
    </section>

    <section class="mt-6">
      <h2 class="text-sm font-semibold mb-2">Recent Traces</h2>
      <ul class="space-y-1 text-xs font-mono">
        <li :for={t <- @traces} class="border-b pb-1"><%= t.directive_type %>: <%= t.status %></li>
      </ul>
      <p :if={@traces == []} class="text-sm text-zinc-500">No recent traces.</p>
    </section>
    """
  end

  defp wid(%{"workspace_id" => id}) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end
  defp wid(_), do: 1
end
