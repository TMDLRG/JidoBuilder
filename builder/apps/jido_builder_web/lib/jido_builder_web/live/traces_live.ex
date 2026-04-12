defmodule JidoBuilderWeb.TracesLive do
  @moduledoc "Phase 4 — Traces viewer: shows signal/directive trace logs."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Observability

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)
    signals = Observability.list_recent_signals(workspace_id, limit: 50)
    directives = Observability.list_recent_directives(workspace_id, limit: 50)

    {:ok,
     assign(socket,
       page_title: "Traces",
       workspace_id: workspace_id,
       signals: signals,
       directives: directives
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <section class="mt-4">
      <h2 class="text-sm font-semibold mb-2">Recent Signals</h2>
      <ul class="space-y-1 text-sm">
        <li :for={s <- @signals} class="font-mono text-xs border-b pb-1">
          <span><%= s.signal_type %></span>
          <span class="ml-2 text-zinc-500"><%= s.status %></span>
        </li>
      </ul>
      <p :if={@signals == []} class="text-sm text-zinc-500">No trace signals yet.</p>
    </section>

    <section class="mt-6">
      <h2 class="text-sm font-semibold mb-2">Recent Directives</h2>
      <ul class="space-y-1 text-sm">
        <li :for={d <- @directives} class="font-mono text-xs border-b pb-1">
          <span><%= d.directive_type %></span>
          <span class="ml-2 text-zinc-500"><%= d.status %></span>
        </li>
      </ul>
      <p :if={@directives == []} class="text-sm text-zinc-500">No trace directives yet.</p>
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
