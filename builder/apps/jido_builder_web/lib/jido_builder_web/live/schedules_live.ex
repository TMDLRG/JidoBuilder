defmodule JidoBuilderWeb.SchedulesLive do
  use JidoBuilderWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, assign(socket, page_title: "Schedules")}

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p>Manage recurring runs and temporal triggers.</p>
    """
  end
end
