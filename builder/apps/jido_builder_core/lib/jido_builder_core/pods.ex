defmodule JidoBuilderCore.Pods do
  import Ecto.Query

  alias JidoBuilderCore.Audit
  alias JidoBuilderCore.Pods.{PodNode, PodTopology}
  alias JidoBuilderCore.Repo

  def list_topologies(workspace_id) do
    PodTopology
    |> where([t], t.workspace_id == ^workspace_id)
    |> Repo.all()
  end

  def list_topologies_with_nodes(workspace_id) do
    PodTopology
    |> where([t], t.workspace_id == ^workspace_id)
    |> Repo.all()
    |> Repo.preload(nodes: :agent_instance)
  end

  def create_topology(attrs, actor),
    do: insert_with_audit(PodTopology, attrs, actor, "pods.topologies.create")

  def create_node(attrs, actor), do: insert_with_audit(PodNode, attrs, actor, "pods.nodes.create")

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
