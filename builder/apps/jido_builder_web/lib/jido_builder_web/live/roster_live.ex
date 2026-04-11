defmodule JidoBuilderWeb.RosterLive do
  use JidoBuilderWeb, :live_view

  @impl true
  def mount(_params, _session, socket),
    do: {:ok, assign(socket, page_title: "Roster / Hire Wizard")}

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p>Build and hire agents into pods.</p>
    """
  end
end
