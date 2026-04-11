defmodule JidoBuilderWeb.WorkflowBuilderLive do
  use JidoBuilderWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, assign(socket, page_title: "Workflow Builder")}

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p>Compose workflow graphs for agent automation.</p>
    """
  end
end
