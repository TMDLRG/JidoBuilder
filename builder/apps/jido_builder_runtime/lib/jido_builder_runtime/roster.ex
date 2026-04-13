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
  alias JidoBuilderRuntime.{BareAgent, Context, DynamicAgent, Error, EventBus, Hiring}

  @pubsub JidoBuilder.PubSub

  @type result(t) :: {:ok, t} | {:error, Error.t()}

  @doc """
  Starts a runtime agent with `display_name` as its ID, persists
  an `agent_instances` row with `status: "running"`, and logs a
  `roster.hire` audit event.

  ## Options

    * `:template_id` — when provided, starts a `DynamicAgent` backed by the
      given template instead of the default `BareAgent`.

  Broadcasts `{:roster_hire, agent_instance}` on the workspace activity
  topic so live views can stream-insert the new row without a DB round-trip.
  """
  @spec hire(pos_integer(), String.t(), String.t(), keyword()) :: result(AgentInstance.t())
  def hire(workspace_id, display_name, actor \\ "roster", opts \\ [])
      when is_integer(workspace_id) and is_binary(display_name) do
    context = %{workspace_id: workspace_id, actor: actor}
    template_id = Keyword.get(opts, :template_id)
    recover? = Keyword.get(opts, :recover, false)

    with {:ok, _ctx} <- Context.validate(context),
         {:ok, {agent_module, agent_opts}} <- resolve_agent(template_id),
         agent_opts <- maybe_restore_state(recover?, workspace_id, display_name, agent_opts),
         {:ok, pid} <- Hiring.start(context, agent_module, [id: display_name] ++ agent_opts),
         {:ok, agent_instance} <- persist_instance(workspace_id, display_name, pid, template_id),
         _ <- Audit.log(actor, "roster.hire", agent_instance, %{pid: inspect(pid), template_id: template_id, recovered: recover?}) do
      broadcast(workspace_id, {:roster_hire, agent_instance})
      {:ok, agent_instance}
    end
  end

  defp maybe_restore_state(false, _ws, _name, opts), do: opts

  defp maybe_restore_state(true, workspace_id, agent_name, opts) do
    case get_last_snapshot(workspace_id, agent_name) do
      nil -> opts
      snapshot when is_map(snapshot) -> Keyword.put(opts, :state, snapshot)
    end
  end

  defp resolve_agent(nil), do: {:ok, {BareAgent, []}}

  defp resolve_agent(template_id) when is_integer(template_id) do
    case DynamicAgent.from_template(template_id) do
      {:ok, agent_struct} ->
        # Pass the module + initial state so AgentServer resolves strategy/0
        # from the concrete DynamicAgent module (not the base Jido.Agent).
        {:ok, {DynamicAgent, [state: agent_struct.state]}}

      {:error, %Error{} = error} ->
        {:error, error}
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
  Stops the Jido agent identified by `agent_name`. Saves a state snapshot
  before shutting down, updates the `agent_instances` row status to
  `"stopped"`, and logs a `roster.stop` audit event.
  """
  @spec stop(pos_integer(), String.t(), String.t()) :: {:ok, AgentInstance.t()} | {:error, Error.t()}
  def stop(workspace_id, agent_name, actor \\ "roster")
      when is_integer(workspace_id) and is_binary(agent_name) do
    context = %{workspace_id: workspace_id, actor: actor}

    with {:ok, _ctx} <- Context.validate(context) do
      # Save state snapshot before stopping
      save_state_snapshot(context, workspace_id, agent_name)

      # Attempt to stop the live process; ignore :not_found (process already dead)
      case Hiring.stop(context, agent_name) do
        :ok -> :ok
        {:error, %Error{code: :not_found}} -> :ok
        {:error, _} = err -> err
      end
      |> case do
        :ok ->
          with {:ok, instance} <- mark_stopped(workspace_id, agent_name) do
            Audit.log(actor, "roster.stop", instance, %{})
            broadcast(workspace_id, {:roster_stop, instance})
            {:ok, instance}
          end
        err -> err
      end
    end
  end

  @doc """
  Returns agents with saved state snapshots that can be recovered.
  These are agents with `status: "stopped"` and non-empty `state`.
  """
  @spec list_recoverable(pos_integer()) :: [AgentInstance.t()]
  def list_recoverable(workspace_id) when is_integer(workspace_id) do
    AgentInstance
    |> where([a], a.workspace_id == ^workspace_id and a.status == "stopped")
    |> where([a], not is_nil(a.state))
    |> order_by([a], desc: a.updated_at)
    |> Repo.all()
    |> Enum.filter(fn a -> a.state != %{} end)
  end

  defp persist_instance(workspace_id, name, pid, template_id) do
    attrs = %{
      workspace_id: workspace_id,
      name: name,
      status: "running",
      runtime_pid: inspect(pid)
    }

    attrs = if template_id, do: Map.put(attrs, :template_id, template_id), else: attrs

    Agents.create_agent_instance(attrs, "roster")
  end

  @doc """
  Updates persisted state snapshot for a running agent instance.
  """
  @spec update_agent_state(pos_integer(), String.t(), map()) ::
          {:ok, AgentInstance.t()} | {:error, Error.t()}
  def update_agent_state(workspace_id, agent_name, state)
      when is_integer(workspace_id) and is_binary(agent_name) and is_map(state) do
    case Repo.one(
           from a in AgentInstance,
             where: a.workspace_id == ^workspace_id and a.name == ^agent_name
         ) do
      nil ->
        {:error, Error.new(:not_found, "agent instance not found", %{name: agent_name})}

      instance ->
        instance
        |> AgentInstance.changeset(%{state: state, last_seen_at: DateTime.utc_now()})
        |> Repo.update()
    end
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

  defp save_state_snapshot(context, workspace_id, agent_name) do
    with {:ok, pid} <- Hiring.whereis(context, agent_name),
         {:ok, agent} <- fetch_agent_state(pid) do
      state_map = extract_state_map(agent)

      if state_map != %{} do
        update_agent_state(workspace_id, agent_name, state_map)
      else
        :ok
      end
    else
      _ -> :ok
    end
  end

  defp fetch_agent_state(pid) do
    try do
      Jido.AgentServer.state(pid)
    catch
      :exit, _ -> {:error, :process_dead}
    end
  end

  defp extract_state_map(server_state) when is_struct(server_state) do
    # Jido.AgentServer.state/1 returns %Jido.AgentServer.State{agent: %Jido.Agent{state: ...}}
    agent = Map.get(server_state, :agent)

    raw_state =
      cond do
        is_struct(agent) -> Map.get(agent, :state, %{})
        is_map(agent) -> Map.get(agent, :state, %{})
        true -> %{}
      end

    to_serializable_map(raw_state)
  end

  defp extract_state_map(value) when is_map(value), do: value
  defp extract_state_map(_), do: %{}

  defp to_serializable_map(value) when is_struct(value), do: Map.from_struct(value) |> to_serializable_map()

  defp to_serializable_map(value) when is_map(value) do
    Map.new(value, fn
      {k, v} when is_struct(v) -> {k, to_serializable_map(v)}
      {k, v} when is_map(v) -> {k, to_serializable_map(v)}
      {k, v} -> {k, v}
    end)
  end

  defp to_serializable_map(value), do: value

  defp get_last_snapshot(workspace_id, agent_name) do
    case Repo.one(
           from a in AgentInstance,
             where:
               a.workspace_id == ^workspace_id and
                 a.name == ^agent_name and
                 a.status == "stopped",
             order_by: [desc: a.updated_at],
             limit: 1
         ) do
      %AgentInstance{state: state} when is_map(state) and state != %{} -> state
      _ -> nil
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
