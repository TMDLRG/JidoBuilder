defmodule JidoBuilderCore.Agents do
  import Ecto.Query

  alias JidoBuilderCore.Audit
  alias JidoBuilderCore.Agents.{AgentInstance, GeneratedModule, Partition, Snapshot, Workspace}
  alias JidoBuilderCore.Repo

  def list_workspaces do
    Workspace |> order_by([w], w.inserted_at) |> Repo.all()
  end

  def list_snapshots(workspace_id) do
    Snapshot
    |> where([s], s.workspace_id == ^workspace_id)
    |> order_by([s], [desc: s.captured_at])
    |> Repo.all()
    |> Repo.preload(:agent_instance)
  end

  def list_partitions(workspace_id) do
    Partition
    |> where([p], p.workspace_id == ^workspace_id)
    |> Repo.all()
  end

  def create_workspace(attrs, actor),
    do: insert_with_audit(Workspace, attrs, actor, "agents.workspaces.create")

  def create_partition(attrs, actor),
    do: insert_with_audit(Partition, attrs, actor, "agents.partitions.create")

  def create_agent_instance(attrs, actor),
    do: insert_with_audit(AgentInstance, attrs, actor, "agents.instances.create")

  def update_agent_instance(agent_instance, attrs, actor) do
    agent_instance
    |> AgentInstance.changeset(attrs)
    |> Repo.update()
    |> maybe_audit(actor, "agents.instances.update")
  end

  def create_generated_module(attrs, actor),
    do: insert_with_audit(GeneratedModule, attrs, actor, "agents.generated_modules.create")

  def create_snapshot(attrs, actor),
    do: insert_with_audit(Snapshot, attrs, actor, "agents.snapshots.create")

  defp insert_with_audit(schema, attrs, actor, action) do
    struct(schema)
    |> schema.changeset(attrs)
    |> Repo.insert()
    |> maybe_audit(actor, action)
  end

  defp maybe_audit({:ok, record} = ok, actor, action) do
    _ = Audit.log(actor, action, record, %{})
    ok
  end

  defp maybe_audit(error, _actor, _action), do: error
end
