defmodule JidoBuilderWeb.WorkflowBuilderLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Workflows
  alias JidoBuilderRuntime.EventBus

  @workspace_id 1

  @impl true
  def mount(_params, _session, socket) do
    workflows = Workflows.list_workflows(@workspace_id)
    current = List.first(workflows)
    steps = if current, do: Workflows.list_workflow_steps(current.id), else: []
    nodes = Enum.map(steps, &step_to_node/1)
    edges = if current, do: Workflows.list_workflow_edges(current.id), else: []

    if connected?(socket) do
      Phoenix.PubSub.subscribe(JidoBuilder.PubSub, EventBus.workspace_activity_topic(@workspace_id))
    end

    {:ok,
     assign(socket,
       page_title: "Workflows",
       workflows: workflows,
       current_workflow: current,
       nodes: nodes,
       edges: encode_edges(edges),
       selected_node: nil
     )}
  end

  @impl true
  def handle_event("node_selected", %{"node_id" => node_id}, socket) do
    {:noreply, assign(socket, selected_node: node_id)}
  end

  def handle_event("node_moved", _params, socket), do: {:noreply, socket}
  def handle_event("edge_created", _params, socket), do: {:noreply, socket}

  def handle_event("select_workflow", %{"id" => wf_id}, socket) do
    workflow_id = parse_id(wf_id)
    wf = Enum.find(socket.assigns.workflows, &(&1.id == workflow_id))
    steps = if wf, do: Workflows.list_workflow_steps(wf.id), else: []
    nodes = Enum.map(steps, &step_to_node/1)
    edges = if wf, do: Workflows.list_workflow_edges(wf.id), else: []
    {:noreply, assign(socket, current_workflow: wf, nodes: nodes, edges: encode_edges(edges), selected_node: nil)}
  end

  def handle_event("create_workflow", %{"workflow" => %{"name" => name}}, socket) do
    user = socket.assigns.current_user

    case Workflows.create_workflow(%{workspace_id: @workspace_id, name: String.trim(name), status: "active"}, user.email) do
      {:ok, workflow} ->
        workflows = Workflows.list_workflows(@workspace_id)
        {:noreply, assign(socket, workflows: workflows, current_workflow: workflow, nodes: [], edges: [])}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  def handle_event("add_step", %{"step" => %{"name" => name, "kind" => kind}}, socket) do
    user = socket.assigns.current_user
    wf = socket.assigns.current_workflow

    if wf do
      order = length(socket.assigns.nodes) + 1

      case Workflows.create_workflow_step(
             %{workflow_id: wf.id, name: String.trim(name), kind: kind, step_order: order, config: %{}},
             user.email
           ) do
        {:ok, _step} ->
          steps = Workflows.list_workflow_steps(wf.id)
          nodes = Enum.map(steps, &step_to_node/1)
          {:noreply, assign(socket, nodes: nodes)}

        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Workflows</.page_header>
    <div class="grid grid-cols-12 gap-4">
      <.card class="col-span-3">
        <:header>Workflow List</:header>
        <ul class="text-sm space-y-1 mb-3">
          <li :for={wf <- @workflows} class={["py-1 border-b cursor-pointer", if(@current_workflow && @current_workflow.id == wf.id, do: "font-bold text-zinc-900", else: "text-zinc-500")]}>
            <button type="button" phx-click="select_workflow" phx-value-id={wf.id} class="w-full text-left">{wf.name}</button>
          </li>
        </ul>
        <form id="create-workflow-form" phx-submit="create_workflow" class="flex gap-2">
          <input type="text" name="workflow[name]" placeholder="New workflow name" required class="border rounded px-2 py-1 text-sm flex-1" />
          <button type="submit" class="rounded bg-zinc-900 px-3 py-1 text-white text-xs">Create</button>
        </form>
        <div :if={@current_workflow} class="mt-4">
          <h3 class="text-xs font-semibold mb-2">Add Step to "{@current_workflow.name}"</h3>
          <form id="add-step-form" phx-submit="add_step" class="space-y-2">
            <input type="text" name="step[name]" placeholder="Step name" required class="border rounded px-2 py-1 text-sm w-full" />
            <select name="step[kind]" class="border rounded px-2 py-1 text-sm w-full">
              <option value="action">action</option>
              <option value="emit">emit</option>
              <option value="condition">condition</option>
              <option value="transform">transform</option>
            </select>
            <button type="submit" class="rounded bg-zinc-900 px-3 py-1 text-white text-xs w-full">Add Step</button>
          </form>
        </div>
      </.card>
      <.card class="col-span-6">
        <:header>Canvas</:header>
        <div id="workflow-dag" phx-hook="WorkflowDag" data-workflow-id={@current_workflow && @current_workflow.id} data-nodes={Jason.encode!(@nodes)} data-edges={Jason.encode!(@edges)} class="min-h-[560px]">
          <span :if={@nodes == []} class="text-zinc-400 text-sm">Empty workflow — add steps on the left</span>
        </div>
      </.card>
      <.card class="col-span-3">
        <:header>Node Config</:header>
        <%= if @selected_node, do: @selected_node, else: "Select a node" %>
      </.card>
    </div>
    """
  end

  defp step_to_node(step) do
    cfg = step.config || %{}
    %{id: step.id, name: step.name, kind: step.kind, x: Map.get(cfg, "x", 40), y: Map.get(cfg, "y", 40)}
  end

  defp encode_edges(edges), do: Enum.map(edges, &%{id: &1.id, source: &1.source_step_id, target: &1.target_step_id, label: &1.label})

  defp parse_id(id) when is_integer(id), do: id
  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} -> n
      _ -> nil
    end
  end
end
