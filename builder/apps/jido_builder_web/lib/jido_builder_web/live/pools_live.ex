defmodule JidoBuilderWeb.PoolsLive do
  @moduledoc "Phase Final A.6 — Pools configuration with live update."
  use JidoBuilderWeb, :live_view

  @default_config %{
    "default_pool" => %{"size" => 5, "max_overflow" => 10},
    "burst_pool" => %{"size" => 2, "max_overflow" => 20}
  }

  @impl true
  def mount(_params, _session, socket) do
    pools = Application.get_env(:jido_builder_runtime, :agent_pools, @default_config)
    {:ok, assign(socket, page_title: "Pools", pools: pools, saved?: false)}
  end

  @impl true
  def handle_event("save", %{"pool" => %{"name" => name, "size" => size, "max_overflow" => max}}, socket) do
    pools =
      Map.put(socket.assigns.pools, name, %{
        "size" => parse_int(size, 1),
        "max_overflow" => parse_int(max, 0)
      })

    Application.put_env(:jido_builder_runtime, :agent_pools, pools)
    {:noreply, assign(socket, pools: pools, saved?: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p class="text-sm text-zinc-500 mb-4">Worker pool configuration for agent execution.</p>

    <table class="text-sm w-full max-w-lg">
      <thead>
        <tr class="border-b text-left text-xs text-zinc-500"><th class="pb-2">Pool</th><th class="pb-2">size</th><th class="pb-2">max_overflow</th></tr>
      </thead>
      <tbody>
        <tr :for={{name, cfg} <- @pools} class="border-b"><td class="py-2 font-mono"><%= name %></td><td class="py-2"><%= cfg["size"] %></td><td class="py-2"><%= cfg["max_overflow"] %></td></tr>
      </tbody>
    </table>

    <form id="pool-config-form" phx-submit="save" class="grid gap-2 max-w-md mt-4">
      <select name="pool[name]" class="border rounded px-2 py-1 text-sm">
        <option :for={{name, _} <- @pools} value={name}><%= name %></option>
      </select>
      <input type="number" name="pool[size]" placeholder="size" class="border rounded px-2 py-1 text-sm" />
      <input type="number" name="pool[max_overflow]" placeholder="max_overflow" class="border rounded px-2 py-1 text-sm" />
      <button type="submit" class="justify-self-start rounded bg-zinc-900 px-3 py-1 text-white text-xs">Update pool</button>
    </form>
    <p :if={@saved?} id="pool-config-saved" class="mt-2 text-xs text-emerald-700">Pool config updated.</p>
    """
  end

  defp parse_int(value, fallback) do
    case Integer.parse(to_string(value || "")) do
      {n, ""} -> n
      _ -> fallback
    end
  end
end
