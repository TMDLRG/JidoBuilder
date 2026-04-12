defmodule JidoBuilderWeb.MemoryLive do
  @moduledoc "Phase 6 — Memory spaces."
  use JidoBuilderWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Memory Spaces")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p class="text-sm text-zinc-500 mb-4">Explore agent memory spaces and stored knowledge.</p>
    <p class="text-sm text-zinc-400 italic">No memory spaces configured yet.</p>
    """
  end
end
