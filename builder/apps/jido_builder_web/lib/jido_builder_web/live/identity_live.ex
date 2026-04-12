defmodule JidoBuilderWeb.IdentityLive do
  @moduledoc "Phase 6 — Identity profiles."
  use JidoBuilderWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Identity Profiles")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p class="text-sm text-zinc-500 mb-4">Manage agent identity profiles and personas.</p>
    <p class="text-sm text-zinc-400 italic">No identity profiles configured yet.</p>
    """
  end
end
