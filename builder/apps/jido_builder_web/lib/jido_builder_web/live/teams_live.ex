defmodule JidoBuilderWeb.TeamsLive do
  use JidoBuilderWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, assign(socket, page_title: "Teams (Pods)")}

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p>Coordinate pods of specialized agents.</p>
    """
  end
end
