defmodule JidoBuilderWeb.MCP.Tools.AgentTool do
  @moduledoc "MCP tool: jido_agent — manage agents."

  alias JidoBuilderRuntime.{Roster, Signals, Hiring}

  def call(%{"action" => "help"}, _ctx), do: {:ok, help_text()}
  def call(%{}, %{workspace_id: nil}), do: {:error, "No workspace context"}

  def call(%{"action" => "list"}, %{workspace_id: ws_id}) do
    agents = Roster.list(ws_id)
    {:ok, Enum.map(agents, fn a -> %{name: a.name, status: a.status, template_id: a.template_id} end)}
  end

  def call(%{"action" => "hire", "name" => name} = args, %{workspace_id: ws_id}) do
    opts = if args["template_id"], do: [template_id: args["template_id"]], else: []
    case Roster.hire(ws_id, name, "mcp", opts) do
      {:ok, inst} -> {:ok, %{name: inst.name, status: inst.status, id: inst.id}}
      {:error, err} -> {:error, inspect(err)}
    end
  end

  def call(%{"action" => "get", "id" => id}, %{workspace_id: ws_id}) do
    agents = Roster.list(ws_id)
    case Enum.find(agents, fn a -> a.name == id end) do
      nil -> {:error, "Agent not found: #{id}"}
      a -> {:ok, %{name: a.name, status: a.status, template_id: a.template_id}}
    end
  end

  def call(%{"action" => "stop", "id" => id}, %{workspace_id: ws_id}) do
    case Roster.stop(ws_id, id, "mcp") do
      {:ok, inst} -> {:ok, %{name: inst.name, status: inst.status}}
      {:error, err} -> {:error, inspect(err)}
    end
  end

  def call(%{"action" => "dispatch", "id" => id} = args, %{workspace_id: ws_id}) do
    context = %{workspace_id: ws_id, actor: "mcp"}
    signal_type = args["signal_type"] || "ping"
    payload = args["payload"] || %{}

    with {:ok, server} <- Hiring.whereis(context, id),
         {:ok, signal} <- Signals.new(context, signal_type, payload) do
      case Signals.timed_call(context, server, signal) do
        {:ok, _state, elapsed_ms} ->
          {:ok, %{status: "success", elapsed_ms: elapsed_ms, correlation_id: signal.extensions[:correlation_id]}}
        {:error, err, elapsed_ms} ->
          {:ok, %{status: "error", elapsed_ms: elapsed_ms, error: inspect(err)}}
      end
    else
      {:error, err} -> {:error, inspect(err)}
    end
  end

  def call(_, _), do: {:ok, help_text()}

  defp help_text do
    """
    jido_agent — Manage Jido agents

    Actions:
      list                    — List all running agents
      hire {name, template_id} — Start a new agent
      get {id}                — Get agent details
      stop {id}               — Stop an agent
      dispatch {id, signal_type, payload} — Send a signal to an agent
      help                    — Show this help
    """
  end
end
