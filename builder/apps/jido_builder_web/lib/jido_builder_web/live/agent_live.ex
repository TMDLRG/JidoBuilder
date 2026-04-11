defmodule JidoBuilderWeb.AgentLive do
  use JidoBuilderWeb, :live_view

  @impl true
  def mount(%{"id" => id}, _session, socket),
    do: {:ok, assign(socket, page_title: "Agent #{id}", agent_id: id)}

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Agent Detail / Activity Stream</.page_header>
    <p>Viewing agent <%= @agent_id %>.</p>
    """
  end
end
