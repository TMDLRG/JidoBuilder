defmodule JidoBuilderCore.Security do
  alias JidoBuilderCore.Audit
  alias JidoBuilderCore.Repo
  alias JidoBuilderCore.Security.{Integration, Secret}

  def create_integration(attrs, actor),
    do: insert_with_audit(Integration, attrs, actor, "security.integrations.create")

  def create_secret(attrs, actor),
    do: insert_with_audit(Secret, attrs, actor, "security.secrets.create")

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
