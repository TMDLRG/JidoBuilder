defmodule JidoBuilderWeb.WorkflowBuilderLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Workflows
  alias JidoBuilderRuntime.{EventBus, WorkflowExecutor}

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)
    workflows = Workflows.list_workflows(workspace_id)
    current = List.first(workflows)
    steps = if current, do: Workflows.list_workflow_steps(current.id), else: []
    nodes = Enum.map(steps, &step_to_node/1)
    edges = if current, do: Workflows.list_workflow_edges(current.id), else: []

    if connected?(socket) do
      Phoenix.PubSub.subscribe(JidoBuilder.PubSub, EventBus.workspace_activity_topic(workspace_id))
    end

    {:ok,
     assign(socket,
       page_title: "Workflows",
       workspace_id: workspace_id,
       workflows: workflows,
       current_workflow: current,
       nodes: nodes,
       edges: encode_edges(edges),
       selected_node: nil,
       selected_step: nil,
       execution_result: nil,
       running: false
     )}
  end

  @impl true
  def handle_event("node_selected", %{"node_id" => node_id}, socket) do
    step_id = parse_id(node_id)
    wf = socket.assigns.current_workflow
    step = if wf, do: Enum.find(Workflows.list_workflow_steps(wf.id), &(&1.id == step_id))
    {:noreply, assign(socket, selected_node: node_id, selected_step: step)}
  end

  def handle_event("node_moved", %{"node_id" => node_id, "x" => x, "y" => y}, socket) do
    step_id = parse_id(node_id)
    wf = socket.assigns.current_workflow

    if wf do
      step = Enum.find(Workflows.list_workflow_steps(wf.id), &(&1.id == step_id))

      if step do
        config = Map.merge(step.config || %{}, %{"x" => x, "y" => y})
        Workflows.update_workflow_step(step, %{config: config}, "web")
      end
    end

    {:noreply, socket}
  end

  def handle_event("node_moved", _params, socket), do: {:noreply, socket}
  def handle_event("edge_created", _params, socket), do: {:noreply, socket}

  def handle_event("delete_step", %{"id" => step_id}, socket) do
    id = parse_id(step_id)
    wf = socket.assigns.current_workflow

    if wf do
      step = Enum.find(Workflows.list_workflow_steps(wf.id), &(&1.id == id))
      if step, do: Workflows.delete_workflow_step(step)

      steps = Workflows.list_workflow_steps(wf.id)
      nodes = Enum.map(steps, &step_to_node/1)
      {:noreply, assign(socket, nodes: nodes, selected_node: nil, selected_step: nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete_workflow", _params, socket) do
    wf = socket.assigns.current_workflow

    if wf do
      Workflows.delete_workflow(wf)
      workflows = Workflows.list_workflows(socket.assigns.workspace_id)
      next = List.first(workflows)
      steps = if next, do: Workflows.list_workflow_steps(next.id), else: []
      nodes = Enum.map(steps, &step_to_node/1)
      edges = if next, do: Workflows.list_workflow_edges(next.id), else: []

      {:noreply,
       assign(socket,
         workflows: workflows,
         current_workflow: next,
         nodes: nodes,
         edges: encode_edges(edges),
         selected_node: nil,
         selected_step: nil,
         execution_result: nil
       )}
    else
      {:noreply, socket}
    end
  end

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

    case Workflows.create_workflow(%{workspace_id: socket.assigns.workspace_id, name: String.trim(name), status: "active"}, user.email) do
      {:ok, workflow} ->
        workflows = Workflows.list_workflows(socket.assigns.workspace_id)
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

  def handle_event("run_workflow", _params, socket) do
    wf = socket.assigns.current_workflow

    if wf do
      user = socket.assigns.current_user
      context = %{workspace_id: socket.assigns.workspace_id, actor: user.email}

      socket = assign(socket, running: true, execution_result: nil)

      case WorkflowExecutor.execute(context, wf.id) do
        {:ok, result} ->
          # Update node colors based on step results
          nodes =
            Enum.map(socket.assigns.nodes, fn node ->
              step_result = Enum.find(result.step_results, &(&1.step_id == node.id))

              status =
                case step_result do
                  %{status: :success} -> "success"
                  %{status: :error} -> "error"
                  _ -> nil
                end

              Map.put(node, :execution_status, status)
            end)

          {:noreply, assign(socket, execution_result: result, running: false, nodes: nodes)}

        {:error, error} ->
          {:noreply, assign(socket, execution_result: %{error: inspect(error)}, running: false)}
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
          <.input_field name="workflow[name]" placeholder="New workflow name" required />
          <button type="submit" class="rounded bg-zinc-900 px-3 py-1 text-white text-xs">Create</button>
        </form>
        <div :if={@current_workflow} class="mt-4">
          <h3 class="text-xs font-semibold mb-2">Add Step to "{@current_workflow.name}"</h3>
          <form id="add-step-form" phx-submit="add_step" class="space-y-2">
            <.input_field name="step[name]" placeholder="Step name" required />
            <.select_field name="step[kind]" label="Kind">
              <option value="action">action</option>
              <option value="emit">emit</option>
              <option value="condition">condition</option>
              <option value="transform">transform</option>
            </.select_field>
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
        <:header>Execution</:header>
        <button
          :if={@current_workflow}
          type="button"
          phx-click="run_workflow"
          disabled={@running}
          class={["rounded px-3 py-2 text-sm text-white w-full mb-3", if(@running, do: "bg-zinc-400", else: "bg-emerald-600 hover:bg-emerald-700")]}
        >
          {if @running, do: "Running…", else: "Run Workflow"}
        </button>

        <div :if={@execution_result && !@execution_result[:error]} class="space-y-2 text-xs">
          <div class="flex items-center gap-2">
            <span class="inline-block w-2 h-2 rounded-full bg-green-500"></span>
            <span class="font-semibold">Completed</span>
            <span class="ml-auto text-zinc-500">{@execution_result.elapsed_ms} ms</span>
          </div>
          <div class="text-zinc-600">Steps: {@execution_result.steps_completed}</div>
          <div class="space-y-1 mt-2">
            <div
              :for={sr <- @execution_result.step_results}
              class={["flex items-center gap-1 py-1 border-b border-zinc-100",
                if(sr.status == :success, do: "text-green-700", else: "text-red-700")
              ]}
            >
              <span class={[
                "inline-block w-1.5 h-1.5 rounded-full",
                if(sr.status == :success, do: "bg-green-500", else: "bg-red-500")
              ]}></span>
              <span>{sr.step_name}</span>
              <span class="ml-auto text-zinc-400">{sr.elapsed_ms} ms</span>
            </div>
          </div>
        </div>

        <div :if={@execution_result && @execution_result[:error]} class="text-xs text-red-700">
          {@execution_result.error}
        </div>

        <div :if={is_nil(@execution_result) && !@running && !@selected_step} class="text-xs text-zinc-400 italic">
          Select a workflow and click Run
        </div>

        <div :if={@selected_step} class="mt-4 pt-3 border-t space-y-2">
          <h4 class="text-xs font-semibold">Selected: {@selected_step.name}</h4>
          <div class="text-xs text-zinc-500">Kind: {@selected_step.kind}</div>
          <div class="text-xs text-zinc-500">Order: {@selected_step.step_order}</div>
          <button phx-click="delete_step" phx-value-id={@selected_step.id} class="text-xs text-red-500 hover:text-red-700" data-confirm="Delete this step?">Delete Step</button>
        </div>

        <div :if={@current_workflow} class="mt-4 pt-3 border-t">
          <button phx-click="delete_workflow" class="text-xs text-red-500 hover:text-red-700" data-confirm="Delete this workflow?">Delete Workflow</button>
        </div>
      </.card>
    </div>
    """
  end

  defp step_to_node(step) do
    cfg = step.config || %{}
    %{id: step.id, name: step.name, kind: step.kind, x: Map.get(cfg, "x", 40), y: Map.get(cfg, "y", 40)}
  end

  defp encode_edges(edges), do: Enum.map(edges, &%{id: &1.id, source: &1.source_step_id, target: &1.target_step_id, label: &1.label})

  defp wid(%{"workspace_id" => id}) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end

  defp wid(_), do: 1

  defp parse_id(id) when is_integer(id), do: id
  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} -> n
      _ -> nil
    end
  end
end
