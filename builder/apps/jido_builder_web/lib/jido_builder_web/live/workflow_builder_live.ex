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
  def handle_event("create_workflow", %{"workflow" => %{"name" => name}}, socket) do
    user = socket.assigns.current_user
    ws_id = socket.assigns.workspace_id

    case Workflows.create_workflow(%{workspace_id: ws_id, name: String.trim(name), status: "active"}, user.email) do
      {:ok, workflow} ->
        workflows = Workflows.list_workflows(ws_id)
        {:noreply, assign(socket, workflows: workflows, current_workflow: workflow, nodes: [])}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  def handle_event("select_workflow", %{"id" => wf_id}, socket) do
    workflow_id = parse_id(wf_id)
    wf = Enum.find(socket.assigns.workflows, &(&1.id == workflow_id))
    steps = if wf, do: Workflows.list_workflow_steps(wf.id), else: []
    nodes = Enum.map(steps, &step_to_node/1)
    {:noreply, assign(socket, current_workflow: wf, nodes: nodes)}
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

    <section class="mt-4 flex gap-6 items-start">
      <div class="flex-1">
        <h2 class="text-sm font-semibold mb-2">Workflows</h2>
        <ul class="text-sm space-y-1 mb-3">
          <li :for={wf <- @workflows} class={"py-1 border-b cursor-pointer #{if @current_workflow && @current_workflow.id == wf.id, do: "font-bold text-zinc-900", else: "text-zinc-500"}"}>
            <button type="button" phx-click="select_workflow" phx-value-id={wf.id} class="w-full text-left"><%= wf.name %></button>
          </li>
        </ul>
        <form id="create-workflow-form" phx-submit="create_workflow" class="flex gap-2">
          <input type="text" name="workflow[name]" placeholder="New workflow name" required class="border rounded px-2 py-1 text-sm flex-1" />
          <button type="submit" class="rounded bg-zinc-900 px-3 py-1 text-white text-xs">Create</button>
        </form>
      </div>

      <div :if={@current_workflow} class="flex-1">
        <h2 class="text-sm font-semibold mb-2">Add Step to "<%= @current_workflow.name %>"</h2>
        <form id="add-step-form" phx-submit="add_step" class="flex gap-2 items-end">
          <div>
            <label class="block text-xs text-zinc-500">Name</label>
            <input type="text" name="step[name]" placeholder="Step name" required class="border rounded px-2 py-1 text-sm" />
          </div>
          <div>
            <label class="block text-xs text-zinc-500">Kind</label>
            <select name="step[kind]" class="border rounded px-2 py-1 text-sm">
              <option value="action">action</option>
              <option value="emit">emit</option>
              <option value="condition">condition</option>
              <option value="transform">transform</option>
            </select>
          </div>
          <button type="submit" class="rounded bg-zinc-900 px-3 py-1 text-white text-xs">Add Step</button>
        </form>
      </div>
    </section>

    <div
      id="workflow-dag"
      phx-hook="WorkflowDag"
      class="mt-4 border rounded bg-zinc-50 min-h-[10rem] p-4 text-sm"
      data-nodes={Jason.encode!(@nodes)}
      data-edges={Jason.encode!(@edges)}
    >
      <span :if={@nodes == []} class="text-zinc-400">Empty workflow — add steps above</span>
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
