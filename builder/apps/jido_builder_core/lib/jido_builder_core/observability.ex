defmodule JidoBuilderCore.Observability do
  import Ecto.Query

  alias JidoBuilderCore.Audit
  alias JidoBuilderCore.Observability.{DirectiveLog, SignalLog}
  alias JidoBuilderCore.Repo

  def log_signal(attrs, actor),
    do: insert_with_audit(SignalLog, attrs, actor, "observability.signals.create")

  def log_directive(attrs, actor),
    do: insert_with_audit(DirectiveLog, attrs, actor, "observability.directives.create")

  def log_error(attrs, actor) do
    attrs
    |> Map.put_new(:directive_type, "runtime.error")
    |> Map.put_new(:status, "error")
    |> log_directive(actor)
  end

  def log_trace(attrs, actor) do
    attrs
    |> Map.put_new(:directive_type, "runtime.trace")
    |> Map.put_new(:status, "ok")
    |> log_directive(actor)
  end

  def list_recent_signals(workspace_id, opts \\ []) do
    workspace_id
    |> signal_query()
    |> maybe_limit(opts)
    |> Repo.all()
  end

  def list_recent_directives(workspace_id, opts \\ []) do
    workspace_id
    |> directive_query()
    |> maybe_limit(opts)
    |> Repo.all()
  end

  def list_recent_errors(workspace_id, opts \\ []) do
    workspace_id
    |> directive_query()
    |> where([log], log.directive_type == "runtime.error")
    |> maybe_limit(opts)
    |> Repo.all()
  end

  def list_recent_traces(workspace_id, opts \\ []) do
    workspace_id
    |> directive_query()
    |> where([log], log.directive_type == "runtime.trace")
    |> maybe_limit(opts)
    |> Repo.all()
  end

  defp signal_query(workspace_id) do
    from(log in SignalLog,
      where: log.workspace_id == ^workspace_id,
      order_by: [desc: log.inserted_at]
    )
  end

  defp directive_query(workspace_id) do
    from(log in DirectiveLog,
      where: log.workspace_id == ^workspace_id,
      order_by: [desc: log.inserted_at]
    )
  end

  defp maybe_limit(query, opts) do
    limit = Keyword.get(opts, :limit, 100)
    from(record in query, limit: ^limit)
  end

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
