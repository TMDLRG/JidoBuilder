defmodule JidoBuilderCore.Pods do
  alias JidoBuilderCore.Audit
  alias JidoBuilderCore.Pods.{PodNode, PodTopology}
  alias JidoBuilderCore.Repo

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
