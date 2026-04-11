defmodule JidoBuilderCore.Observability do
  alias JidoBuilderCore.Audit
  alias JidoBuilderCore.Observability.{DirectiveLog, SignalLog}
  alias JidoBuilderCore.Repo

  def log_signal(attrs, actor),
    do: insert_with_audit(SignalLog, attrs, actor, "observability.signals.create")

  def log_directive(attrs, actor),
    do: insert_with_audit(DirectiveLog, attrs, actor, "observability.directives.create")

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
