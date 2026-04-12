defmodule JidoBuilderRuntime.Roster do
  @moduledoc """
  Workspace-aware roster operations: hire, list, and stop agents.

  Wraps `JidoBuilderRuntime.Hiring` for the Jido lifecycle and adds
  database persistence (`agent_instances`) plus `roster.*` audit events
  on top of the lower-level directive log that `Hiring` writes.
  """
  import Ecto.Query

  alias JidoBuilderCore.{Agents, Audit, Repo}
  alias JidoBuilderCore.Agents.AgentInstance
  alias JidoBuilderCore.Audit.AuditEvent
  alias JidoBuilderRuntime.{BareAgent, Context, Error, EventBus, Hiring}

  @pubsub JidoBuilder.PubSub

  @type result(t) :: {:ok, t} | {:error, Error.t()}

  @doc """
  Starts a bare runtime agent with `display_name` as its ID, persists
  an `agent_instances` row with `status: "running"`, and logs a
  `roster.hire` audit event.

  Broadcasts `{:roster_hire, agent_instance}` on the workspace activity
  topic so live views can stream-insert the new row without a DB round-trip.
  """
  @spec hire(pos_integer(), String.t(), String.t()) :: result(AgentInstance.t())
  def hire(workspace_id, display_name, actor \\ "roster")
      when is_integer(workspace_id) and is_binary(display_name) do
    context = %{workspace_id: workspace_id, actor: actor}

    with {:ok, _ctx} <- Context.validate(context),
         {:ok, pid} <- Hiring.start(context, BareAgent, id: display_name),
         {:ok, agent_instance} <- persist_instance(workspace_id, display_name, pid),
         _ <- Audit.log(actor, "roster.hire", agent_instance, %{pid: inspect(pid)}) do
      broadcast(workspace_id, {:roster_hire, agent_instance})
      {:ok, agent_instance}
    end
  end

  @doc """
  Returns all `agent_instances` rows for `workspace_id` with
  `status: "running"`, ordered newest-first.
  """
  @spec list(pos_integer()) :: [AgentInstance.t()]
  def list(workspace_id) when is_integer(workspace_id) do
    AgentInstance
    |> where([a], a.workspace_id == ^workspace_id and a.status == "running")
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
  end

  @doc """
  Stops the Jido agent identified by `agent_name`, updates the
  `agent_instances` row status to `"stopped"`, and logs a `roster.stop`
  audit event.
  """
  @spec stop(pos_integer(), String.t(), String.t()) :: {:ok, AgentInstance.t()} | {:error, Error.t()}
  def stop(workspace_id, agent_name, actor \\ "roster")
      when is_integer(workspace_id) and is_binary(agent_name) do
    context = %{workspace_id: workspace_id, actor: actor}

    with {:ok, _ctx} <- Context.validate(context),
         :ok <- Hiring.stop(context, agent_name),
         {:ok, instance} <- mark_stopped(workspace_id, agent_name) do
      Audit.log(actor, "roster.stop", instance, %{})
      broadcast(workspace_id, {:roster_stop, instance})
      {:ok, instance}
    end
  end

  defp persist_instance(workspace_id, name, pid) do
    Agents.create_agent_instance(
      %{
        workspace_id: workspace_id,
        name: name,
        status: "running",
        runtime_pid: inspect(pid)
      },
      "roster"
    )
  end

  defp mark_stopped(workspace_id, agent_name) do
    case Repo.one(
           from a in AgentInstance,
             where: a.workspace_id == ^workspace_id and a.name == ^agent_name
         ) do
      nil ->
        {:error, Error.new(:not_found, "agent instance not found", %{name: agent_name})}

      instance ->
        instance
        |> AgentInstance.changeset(%{status: "stopped"})
        |> Repo.update()
    end
  end

  defp broadcast(workspace_id, message) do
    if Process.whereis(@pubsub) do
      Phoenix.PubSub.broadcast(@pubsub, EventBus.workspace_activity_topic(workspace_id), message)
    end

    :ok
  end

  @doc """
  Logs a plain `roster.hire` audit event using raw attrs.
  Kept for contexts where an `AgentInstance` struct is unavailable.
  """
  def log_audit_action(workspace_id, actor, action, entity_id) do
    attrs = %{
      workspace_id: workspace_id,
      actor: actor,
      action: action,
      entity_type: "Elixir.JidoBuilderCore.Agents.AgentInstance",
      entity_id: to_string(entity_id),
      metadata: %{},
      occurred_at: DateTime.utc_now()
    }

    %AuditEvent{}
    |> AuditEvent.changeset(attrs)
    |> Repo.insert()
  end
end
