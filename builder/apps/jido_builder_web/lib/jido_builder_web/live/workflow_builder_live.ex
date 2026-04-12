defmodule JidoBuilderWeb.WorkflowBuilderLive do
  @moduledoc """
  Phase 3.5 — Playbooks / Workflow Builder (D3 DAG).

  The LV holds workflow nodes + edges as assigns.  On mount it pushes
  `init_graph` to the WorkflowDag JS hook.  The hook sends back
  `node_moved` and `edge_upserted` / `edge_removed` events which are
  persisted to `workflow_steps`.  A `save_workflow` event replaces all
  steps for the workflow with the current client state.
  """
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.{Workflows}
  alias JidoBuilderRuntime.EventBus

  @workspace_id 1
  @stream_limit 200

  @impl true
  def mount(params, _session, socket) do
    workspace_id = workspace_id_from_params(params)

    topics = [
      EventBus.workspace_activity_topic(workspace_id),
      EventBus.workflow_activity_topic(workspace_id)
    ]

    workflows = Workflows.list_workflows(workspace_id)
    current_workflow = List.first(workflows)

    steps =
      if current_workflow,
        do: Workflows.list_workflow_steps(current_workflow.id),
        else: []

    nodes = Enum.map(steps, &step_to_node/1)

    socket =
      socket
      |> assign(
        page_title: "Workflow Builder",
        topics: topics,
        workspace_id: workspace_id,
        workflows: workflows,
        current_workflow: current_workflow,
        nodes: nodes,
        edges: []
      )
      |> stream(:workflow_events, [], limit: -@stream_limit)

    if connected?(socket) do
      Enum.each(topics, &Phoenix.PubSub.subscribe(JidoBuilder.PubSub, &1))
      push_event(socket, "init_graph", %{nodes: nodes, edges: []})
    else
      socket
    end

    {:ok, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    Enum.each(socket.assigns.topics, &Phoenix.PubSub.unsubscribe(JidoBuilder.PubSub, &1))
    :ok
  end

  @impl true
  def handle_event("save_workflow", %{"workflow_id" => wf_id, "nodes" => nodes}, socket) do
    user = socket.assigns.current_user
    workflow_id = parse_id(wf_id)

    Workflows.delete_workflow_steps(workflow_id)

    Enum.each(nodes, fn node ->
      Workflows.create_workflow_step(
        %{
          workflow_id: workflow_id,
          name: Map.get(node, "name", "step"),
          step_order: Map.get(node, "step_order", 1),
          kind: Map.get(node, "kind", "action"),
          config: Map.get(node, "config", %{})
        },
        user.email
      )
    end)

    steps = Workflows.list_workflow_steps(workflow_id)
    updated_nodes = Enum.map(steps, &step_to_node/1)
    {:noreply, assign(socket, nodes: updated_nodes)}
  end

  @impl true
  def handle_event("node_moved", %{"name" => name, "x" => x, "y" => y, "workflow_id" => wf_id}, socket) do
    user = socket.assigns.current_user
    workflow_id = parse_id(wf_id)

    import Ecto.Query
    alias JidoBuilderCore.{Repo, Workflows.WorkflowStep}

    step = Repo.one(from s in WorkflowStep, where: s.workflow_id == ^workflow_id and s.name == ^name)

    if step do
      new_config = Map.merge(step.config || %{}, %{"x" => x, "y" => y})
      Workflows.update_workflow_step(step, %{config: new_config}, user.email)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("edge_upserted", %{"from" => _from, "to" => _to}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("edge_removed", %{"from" => _from, "to" => _to}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:jido_event, event}, socket) do
    {:noreply, stream_insert(socket, :workflow_events, event, at: 0, limit: @stream_limit)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <div
      id="workflow-dag"
      phx-hook="WorkflowDag"
      class="mt-4 border rounded bg-zinc-50 h-64 flex items-center justify-center text-zinc-400 text-sm"
      data-nodes={Jason.encode!(@nodes)}
      data-edges={Jason.encode!(@edges)}
    >
      <span>WorkflowDag canvas — D3 renders here when JS is loaded</span>
    </div>

    <section class="mt-4">
      <h2 class="text-base font-semibold">Workflow Execution Stream</h2>
      <ul id="workflow-events" phx-update="stream" class="mt-2 space-y-1 text-sm">
        <li :for={{dom_id, event} <- @streams.workflow_events} id={dom_id}>
          <span class="font-mono"><%= event.event_name %></span>
          <span class="ml-2 text-zinc-600">status=<%= event.status %></span>
        </li>
      </ul>
    </section>
    """
  end

  defp step_to_node(step) do
    config = step.config || %{}
    %{
      id: "step-#{step.id}",
      name: step.name,
      kind: step.kind,
      step_order: step.step_order,
      x: Map.get(config, "x", 0),
      y: Map.get(config, "y", 0)
    }
  end

  defp parse_id(id) when is_integer(id), do: id
  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} -> n
      _ -> nil
    end
  end

  defp workspace_id_from_params(%{"workspace_id" => id}) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> @workspace_id
    end
  end

  defp workspace_id_from_params(_), do: @workspace_id
end
