defmodule JidoBuilderWeb.ThreadsLive do
  @moduledoc "Phase 6 — Threads explorer."
  use JidoBuilderWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Threads")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p class="text-sm text-zinc-500 mb-4">Browse agent conversation threads.</p>
    <p class="text-sm text-zinc-400 italic">No threads yet. Start an agent conversation to see threads here.</p>
    """
  end
end
