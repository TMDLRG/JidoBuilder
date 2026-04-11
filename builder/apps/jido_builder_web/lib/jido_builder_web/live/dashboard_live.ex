defmodule JidoBuilderWeb.DashboardLive do
  use JidoBuilderWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Home Dashboard")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p>Welcome to Jido Builder.</p>
    """
  end
end
