defmodule JidoBuilderWeb.DebugLive do
  @moduledoc "Story 7.2 — Debug console with REPL, state inspector, and log stream."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Observability
  alias JidoBuilderRuntime.{Hiring, Signals}

  @impl true
  def mount(params, _session, socket) do
    workspace_id = wid(params)

    {:ok,
     assign(socket,
       page_title: "Debug",
       workspace_id: workspace_id,
       errors: Observability.list_recent_errors(workspace_id, limit: 20),
       traces: Observability.list_recent_traces(workspace_id, limit: 20),
       debug_enabled: Application.get_env(:jido_builder_runtime, :debug_enabled, false),
       agents: list_agents(workspace_id),
       selected_agent: nil,
       agent_state: nil,
       repl_result: nil,
       repl_error: nil,
       log_filter: "",
       log_entries: Observability.list_recent_signals(workspace_id, limit: 50)
     )}
  end

  @impl true
  def handle_event("toggle_debug", _params, socket) do
    enabled = not socket.assigns.debug_enabled
    Application.put_env(:jido_builder_runtime, :debug_enabled, enabled)
    {:noreply, assign(socket, debug_enabled: enabled)}
  end

  def handle_event("inspect_agent", %{"name" => name}, socket) do
    context = %{workspace_id: socket.assigns.workspace_id, actor: "debug"}

    state =
      case Hiring.whereis(context, name) do
        {:ok, server} ->
          try do
            Jido.AgentServer.state(server)
          rescue
            _ -> %{error: "Could not read state"}
          catch
            _, _ -> %{error: "Agent not responding"}
          end

        {:error, _} ->
          %{error: "Agent not found or not running"}
      end

    {:noreply, assign(socket, selected_agent: name, agent_state: state)}
  end

  def handle_event("debug_signal", %{"debug" => %{"agent" => agent, "signal_type" => sig_type, "payload" => payload_str}}, socket) do
    context = %{workspace_id: socket.assigns.workspace_id, actor: "debug-console"}

    payload =
      case Jason.decode(payload_str) do
        {:ok, map} when is_map(map) -> map
        _ -> %{}
      end

    result =
      with {:ok, server} <- Hiring.whereis(context, agent),
           {:ok, signal} <- Signals.new(context, sig_type, payload) do
        case Signals.timed_call(context, server, signal) do
          {:ok, state, elapsed} ->
            {:ok, %{state: inspect(state, limit: 50), elapsed_ms: elapsed}}

          {:error, error, elapsed} ->
            {:error, "Error after #{elapsed}ms: #{inspect(error)}"}
        end
      else
        {:error, err} -> {:error, inspect(err)}
      end

    case result do
      {:ok, data} -> {:noreply, assign(socket, repl_result: data, repl_error: nil)}
      {:error, msg} -> {:noreply, assign(socket, repl_result: nil, repl_error: msg)}
    end
  end

  def handle_event("filter_logs", %{"q" => query}, socket) do
    {:noreply, assign(socket, log_filter: query)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>

    <div class="mb-4">
      <.button phx-click="toggle_debug" id="debug-toggle">
        Toggle debug ({if @debug_enabled, do: "on", else: "off"})
      </.button>
    </div>

    <div class="grid md:grid-cols-2 gap-4">
      <%!-- Agent State Inspector --%>
      <.card>
        <:header>Agent State Inspector</:header>
        <div class="space-y-2">
          <div :for={a <- @agents} class="flex items-center gap-2">
            <button phx-click="inspect_agent" phx-value-name={a.name} class="text-sm ui-link">{a.name}</button>
            <.badge variant={if @debug_enabled, do: "success", else: "default"}>{a.status}</.badge>
          </div>
          <.empty_state :if={@agents == []} title="No agents" description="No running agents." icon="users" />
        </div>
        <pre :if={@agent_state} class="mt-3 rounded bg-zinc-50 border p-2 text-xs font-mono whitespace-pre-wrap overflow-auto max-h-48">
          {inspect(@agent_state, pretty: true, limit: :infinity)}
        </pre>
      </.card>

      <%!-- Signal Injection (REPL) --%>
      <.card>
        <:header>Signal Injection</:header>
        <form id="debug-signal-form" phx-submit="debug_signal" class="space-y-2">
          <.select_field name="debug[agent]" label="Agent">
            <option value="">Select agent...</option>
            <option :for={a <- @agents} value={a.name}>{a.name}</option>
          </.select_field>
          <.input_field name="debug[signal_type]" label="Signal Type" value="" />
          <label class="ui-label">Payload (JSON)</label>
          <textarea name="debug[payload]" class="ui-input font-mono text-xs" rows="3">{}</textarea>
          <.button>Send Signal</.button>
        </form>
        <div :if={@repl_result} class="mt-3 p-2 rounded bg-green-50 border border-green-200 text-xs font-mono">
          Result: {inspect(@repl_result, pretty: true)}
        </div>
        <div :if={@repl_error} class="mt-3 p-2 rounded bg-red-50 border border-red-200 text-xs font-mono text-red-700">
          Error: {@repl_error}
        </div>
      </.card>
    </div>

    <%!-- Log Stream --%>
    <.card class="mt-4">
      <:header>Log Stream</:header>
      <form phx-change="filter_logs" class="mb-2">
        <input type="text" name="q" id="log-filter" value={@log_filter} placeholder="Filter logs (grep)..." class="ui-input" phx-debounce="200" />
      </form>
      <ul class="space-y-1 max-h-64 overflow-y-auto text-xs font-mono">
        <li :for={entry <- filtered_logs(@log_entries, @log_filter)} class="border-b pb-1">
          <span class="text-zinc-400">{format_time(entry.inserted_at)}</span>
          <.badge variant={log_badge(entry.direction)}>{entry.direction}</.badge>
          <span>{entry.signal_type}</span>
        </li>
      </ul>
      <.empty_state :if={filtered_logs(@log_entries, @log_filter) == []} title="No logs" description="No matching log entries." icon="eye" />
    </.card>

    <%!-- Error + Trace panels --%>
    <div class="grid md:grid-cols-2 gap-4 mt-4">
      <.card>
        <:header>Recent Errors</:header>
        <ul class="space-y-1 text-xs font-mono">
          <li :for={e <- @errors} class="border-b pb-1"><.badge variant="danger">{e.directive_type}</.badge> {e.status}</li>
        </ul>
        <.empty_state :if={@errors == []} title="No errors" description="No recent errors." icon="check_circle" />
      </.card>

      <.card>
        <:header>Recent Traces</:header>
        <ul class="space-y-1 text-xs font-mono">
          <li :for={t <- @traces} class="border-b pb-1">{t.directive_type}: {t.status}</li>
        </ul>
        <.empty_state :if={@traces == []} title="No traces" description="No recent traces." icon="eye" />
      </.card>
    </div>
    """
  end

  defp filtered_logs(entries, ""), do: entries
  defp filtered_logs(entries, nil), do: entries

  defp filtered_logs(entries, query) do
    q = String.downcase(query)

    Enum.filter(entries, fn e ->
      String.contains?(String.downcase(e.signal_type || ""), q) ||
        String.contains?(String.downcase(e.direction || ""), q)
    end)
  end

  defp format_time(nil), do: "-"
  defp format_time(dt), do: Calendar.strftime(dt, "%H:%M:%S")

  defp log_badge("inbound"), do: "success"
  defp log_badge("outbound"), do: "info"
  defp log_badge("error"), do: "danger"
  defp log_badge(_), do: "neutral"

  defp list_agents(workspace_id) do
    import Ecto.Query
    alias JidoBuilderCore.{Agents.AgentInstance, Repo}

    AgentInstance
    |> where([a], a.workspace_id == ^workspace_id)
    |> order_by([a], [asc: a.inserted_at])
    |> Repo.all()
  end

  defp wid(%{"workspace_id" => id}) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end

  defp wid(_), do: 1
end
