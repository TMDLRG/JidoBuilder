defmodule JidoBuilderWeb.PoolsLive do
  @moduledoc "Phase 4 — Pools: worker pool configuration view."
  use JidoBuilderWeb, :live_view

  @default_config %{
    "default_pool" => %{"size" => 5, "max_overflow" => 10},
    "burst_pool" => %{"size" => 2, "max_overflow" => 20}
  }

  @impl true
  def mount(_params, _session, socket) do
    pools = Application.get_env(:jido_builder_runtime, :agent_pools, @default_config)

    {:ok, assign(socket, page_title: "Pools", pools: pools)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p class="text-sm text-zinc-500 mb-4">Worker pool configuration for agent execution.</p>
    <table class="text-sm w-full max-w-lg">
      <thead>
        <tr class="border-b text-left text-xs text-zinc-500">
          <th class="pb-2">Pool</th>
          <th class="pb-2">size</th>
          <th class="pb-2">max_overflow</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={{name, cfg} <- @pools} class="border-b">
          <td class="py-2 font-mono"><%= name %></td>
          <td class="py-2"><%= cfg["size"] || cfg[:size] || "—" %></td>
          <td class="py-2"><%= cfg["max_overflow"] || cfg[:max_overflow] || "—" %></td>
        </tr>
      </tbody>
    </table>
    """
  end
end
