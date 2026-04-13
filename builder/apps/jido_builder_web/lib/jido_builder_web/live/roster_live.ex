defmodule JidoBuilderWeb.RosterLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Templates
  alias JidoBuilderRuntime.{EventBus, Roster}

  @impl true
  def mount(params, _session, socket) do
    workspace_id = workspace_id_from_params(params)
    agents = Roster.list(workspace_id)
    templates = Templates.list_templates(workspace_id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(JidoBuilder.PubSub, EventBus.workspace_activity_topic(workspace_id))
    end

    socket =
      socket
      |> assign(
        page_title: "Agents",
        workspace_id: workspace_id,
        templates: templates,
        all_agents: agents,
        search_query: "",
        status_filter: "all",
        show_hire: false,
        pending_stop: nil,
        form_error: nil
      )
      |> stream(:agents, agents)

    {:ok, socket}
  end

  defp template_display_name(agent, templates) do
    case agent.template_id do
      nil -> "bare"
      tid -> Enum.find_value(templates, "bare", fn t -> if t.id == tid, do: t.name end)
    end
  end

  defp workspace_id_from_params(%{"workspace_id" => id}) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end

  defp workspace_id_from_params(_), do: 1

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply, apply_filters(socket, query, socket.assigns.status_filter)}
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply, apply_filters(socket, socket.assigns.search_query, status)}
  end

  def handle_event("open_hire", _, socket), do: {:noreply, assign(socket, show_hire: true)}
  def handle_event("close_hire", _, socket), do: {:noreply, assign(socket, show_hire: false)}

  def handle_event("hire_agent", %{"hire" => params}, socket) do
    actor = socket.assigns.current_user.email
    workspace_id = socket.assigns.workspace_id
    name = String.trim(params["name"] || "")

    opts =
      case params["template_id"] do
        nil -> []
        "" -> []
        id -> [template_id: String.to_integer(id)]
      end

    case Roster.hire(workspace_id, name, actor, opts) do
      {:ok, agent_instance} ->
        {:noreply,
         socket
         |> assign(show_hire: false, form_error: nil)
         |> stream_insert(:agents, agent_instance, at: 0)}

      {:error, error} ->
        {:noreply, assign(socket, form_error: inspect(error))}
    end
  end

  def handle_event("request_stop", %{"name" => name}, socket) do
    {:noreply, assign(socket, pending_stop: name)}
  end

  def handle_event("cancel_stop", _, socket), do: {:noreply, assign(socket, pending_stop: nil)}

  def handle_event("confirm_stop", %{"name" => agent_name}, socket) do
    actor = socket.assigns.current_user.email

    case Roster.stop(socket.assigns.workspace_id, agent_name, actor) do
      {:ok, instance} ->
        {:noreply,
         socket
         |> assign(pending_stop: nil, form_error: nil)
         |> stream_delete(:agents, instance)}

      {:error, error} ->
        {:noreply, assign(socket, form_error: inspect(error))}
    end
  end

  @impl true
  def handle_info({:roster_hire, agent_instance}, socket) do
    {:noreply, stream_insert(socket, :agents, agent_instance, at: 0)}
  end

  def handle_info({:roster_stop, agent_instance}, socket) do
    {:noreply, stream_delete(socket, :agents, agent_instance)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp apply_filters(socket, query, status_filter) do
    filtered =
      socket.assigns.all_agents
      |> filter_by_search(query)
      |> filter_by_status(status_filter)

    socket
    |> assign(search_query: query, status_filter: status_filter)
    |> stream(:agents, filtered, reset: true)
  end

  defp filter_by_search(agents, ""), do: agents
  defp filter_by_search(agents, nil), do: agents

  defp filter_by_search(agents, query) do
    q = String.downcase(query)
    Enum.filter(agents, fn a -> String.contains?(String.downcase(a.name), q) end)
  end

  defp filter_by_status(agents, "all"), do: agents
  defp filter_by_status(agents, status), do: Enum.filter(agents, &(&1.status == status))

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Agents <:actions><button phx-click="open_hire" class="ui-btn primary">Hire</button></:actions></.page_header>

    <p :if={@form_error} class="mb-4 text-sm text-red-600">{@form_error}</p>

    <div class="flex flex-col sm:flex-row gap-3 mb-4">
      <form phx-change="search" class="flex-1">
        <input type="text" name="q" value={@search_query} placeholder="Search agents..." class="ui-input" phx-debounce="200" />
      </form>
      <form phx-change="filter_status">
        <select name="status" class="ui-input w-auto" value={@status_filter}>
          <option value="all" selected={@status_filter == "all"}>All Statuses</option>
          <option value="running" selected={@status_filter == "running"}>Running</option>
          <option value="stopped" selected={@status_filter == "stopped"}>Stopped</option>
        </select>
      </form>
    </div>

    <section id="roster-agents" phx-update="stream" class="grid md:grid-cols-3 gap-4">
      <div :for={{dom_id, agent} <- @streams.agents} id={dom_id}>
        <.card>
          <:header><div class="flex justify-between"><span>{agent.name}</span><.badge variant="success">{agent.status}</.badge></div></:header>
          <div class="text-xs text-zinc-500">template: {template_display_name(agent, @templates)}</div>
          <:footer><.link navigate={~p"/agents/#{agent.name}"} class="text-sm">View</.link> <button phx-click="request_stop" phx-value-name={agent.name} class="text-sm text-red-600">Stop</button></:footer>
        </.card>
      </div>
    </section>

    <.modal id="hire-modal" show={@show_hire}>
      <.card>
        <:header>Hire Agent</:header>
        <form id="hire-form" phx-submit="hire_agent" class="space-y-3">
          <.input_field name="hire[name]" label="Agent name" />
          <.select_field name="hire[template_id]" label="Template">
            <option value="">Bare Agent</option>
            <option :for={t <- @templates} value={t.id}>{t.name}</option>
          </.select_field>
          <div class="flex gap-2 mt-2">
            <.button>Hire</.button>
            <button phx-click="close_hire" type="button" class="ui-btn secondary">Cancel</button>
          </div>
        </form>
      </.card>
    </.modal>

    <.modal id="stop-modal" show={not is_nil(@pending_stop)}>
      <.card>
        <:header>Stop Agent</:header>
        <p>Stop {@pending_stop}? In-flight tasks will be cancelled.</p>
        <:footer>
          <button phx-click="confirm_stop" phx-value-name={@pending_stop} class="ui-btn danger">Stop</button>
          <button phx-click="cancel_stop" class="ui-btn secondary">Cancel</button>
        </:footer>
      </.card>
    </.modal>
    """
  end
end
