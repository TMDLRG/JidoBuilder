defmodule JidoBuilderWeb.WorkflowBuilderLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Workflows

  @impl true
  def mount(_params, _session, socket) do
    workflows = Workflows.list_workflows(1)
    current = List.first(workflows)
    nodes = if current, do: Enum.map(Workflows.list_workflow_steps(current.id), &step_to_node/1), else: []
    edges = if current, do: Workflows.list_workflow_edges(current.id), else: []
    {:ok, assign(socket, workflows: workflows, current_workflow: current, nodes: nodes, edges: encode_edges(edges), selected_node: nil)}
  end

  def handle_event("node_selected", %{"node_id" => node_id}, socket), do: {:noreply, assign(socket, selected_node: node_id)}
  def handle_event("node_moved", _params, socket), do: {:noreply, socket}
  def handle_event("edge_created", _params, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <.page_header>Workflows</.page_header>
    <div class="grid grid-cols-12 gap-4">
      <.card class="col-span-3"><:header>Workflow List</:header><ul><li :for={w <- @workflows}>{w.name}</li></ul></.card>
      <.card class="col-span-6"><:header>Canvas</:header><div id="workflow-dag" phx-hook="WorkflowDag" data-workflow-id={@current_workflow && @current_workflow.id} data-nodes={Jason.encode!(@nodes)} data-edges={Jason.encode!(@edges)} class="min-h-[560px]"></div></.card>
      <.card class="col-span-3"><:header>Node Config</:header><%= if @selected_node, do: @selected_node, else: "Select a node" %></.card>
    </div>
    """
  end

  defp step_to_node(step) do
    cfg = step.config || %{}
    %{id: step.id, name: step.name, kind: step.kind, x: Map.get(cfg, "x", 40), y: Map.get(cfg, "y", 40)}
  end

  defp encode_edges(edges), do: Enum.map(edges, &%{id: &1.id, source: &1.source_step_id, target: &1.target_step_id, label: &1.label})
end
