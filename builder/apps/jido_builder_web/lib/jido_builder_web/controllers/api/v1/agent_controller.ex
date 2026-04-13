defmodule JidoBuilderWeb.Api.V1.AgentController do
  @moduledoc """
  Story 4.2 — REST API for agent CRUD and dispatch.
  """
  use JidoBuilderWeb, :controller

  alias JidoBuilderRuntime.{Roster, Signals, Hiring}

  def index(conn, params) do
    workspace_id = conn.assigns.workspace_id
    {limit, offset} = parse_pagination(params)
    all_agents = Roster.list(workspace_id)
    page = all_agents |> Enum.drop(offset) |> Enum.take(limit)

    json(conn, %{
      data: Enum.map(page, &serialize_agent/1),
      meta: %{total: length(all_agents), limit: limit, offset: offset}
    })
  end

  def create(conn, %{"name" => name} = params) do
    workspace_id = conn.assigns.workspace_id
    actor = "api:#{conn.assigns.api_key.id}"

    opts =
      case params["template_id"] do
        nil -> []
        "" -> []
        tid when is_integer(tid) -> [template_id: tid]
        tid when is_binary(tid) -> [template_id: String.to_integer(tid)]
      end

    case Roster.hire(workspace_id, name, actor, opts) do
      {:ok, instance} ->
        conn |> put_status(201) |> json(%{data: serialize_agent(instance)})

      {:error, error} ->
        conn |> put_status(422) |> json(%{error: inspect(error)})
    end
  end

  def show(conn, %{"id" => agent_name}) do
    workspace_id = conn.assigns.workspace_id
    agents = Roster.list(workspace_id)

    case Enum.find(agents, fn a -> a.name == agent_name end) do
      nil -> conn |> put_status(404) |> json(%{error: "Agent not found"})
      agent -> json(conn, %{data: serialize_agent(agent)})
    end
  end

  def delete(conn, %{"id" => agent_name}) do
    workspace_id = conn.assigns.workspace_id
    actor = "api:#{conn.assigns.api_key.id}"

    case Roster.stop(workspace_id, agent_name, actor) do
      {:ok, instance} -> json(conn, %{data: serialize_agent(instance)})
      {:error, error} -> conn |> put_status(422) |> json(%{error: inspect(error)})
    end
  end

  def dispatch(conn, %{"id" => agent_name} = params) do
    workspace_id = conn.assigns.workspace_id
    actor = "api:#{conn.assigns.api_key.id}"
    context = %{workspace_id: workspace_id, actor: actor}
    signal_type = params["signal_type"] || "ping"
    payload = params["payload"] || %{}

    with {:ok, server} <- Hiring.whereis(context, agent_name),
         {:ok, signal} <- Signals.new(context, signal_type, payload) do
      case Signals.timed_call(context, server, signal) do
        {:ok, agent_state, elapsed_ms} ->
          json(conn, %{
            data: %{
              status: "success",
              elapsed_ms: elapsed_ms,
              correlation_id: signal.extensions[:correlation_id],
              agent_state: inspect(agent_state, limit: 50)
            }
          })

        {:error, error, elapsed_ms} ->
          conn
          |> put_status(422)
          |> json(%{
            data: %{status: "error", elapsed_ms: elapsed_ms, error: inspect(error)}
          })
      end
    else
      {:error, error} ->
        conn |> put_status(422) |> json(%{error: inspect(error)})
    end
  end

  defp parse_pagination(params) do
    limit =
      case params["limit"] do
        nil -> 50
        val when is_binary(val) -> val |> String.to_integer() |> max(1) |> min(100)
        val when is_integer(val) -> val |> max(1) |> min(100)
        _ -> 50
      end

    offset =
      case params["offset"] do
        nil -> 0
        val when is_binary(val) -> val |> String.to_integer() |> max(0)
        val when is_integer(val) -> max(val, 0)
        _ -> 0
      end

    {limit, offset}
  end

  defp serialize_agent(agent) do
    %{
      id: agent.id,
      name: agent.name,
      status: agent.status,
      template_id: agent.template_id,
      inserted_at: agent.inserted_at
    }
  end
end
