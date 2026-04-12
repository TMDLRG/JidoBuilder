defmodule JidoBuilderCore.Audit do
  @moduledoc """
  Shared audit logging API used by write contexts.
  """

  import Ecto.Query

  alias JidoBuilderCore.Audit.AuditEvent
  alias JidoBuilderCore.Repo

  def log(actor, action, %{__struct__: struct, id: id} = subject, metadata) do
    workspace_id =
      case subject do
        %JidoBuilderCore.Agents.Workspace{} -> id
        _ -> Map.get(subject, :workspace_id)
      end

    attrs = %{
      workspace_id: workspace_id,
      actor: actor,
      action: action,
      entity_type: Atom.to_string(struct),
      entity_id: to_string(id),
      metadata: metadata,
      occurred_at: DateTime.utc_now()
    }

    %AuditEvent{}
    |> AuditEvent.changeset(attrs)
    |> Repo.insert()
  end

  def list_audit_events(filters \\ %{}) do
    AuditEvent
    |> maybe_filter_workspace(filters)
    |> order_by([e], desc: e.occurred_at)
    |> Repo.all()
  end

  defp maybe_filter_workspace(query, %{workspace_id: workspace_id}) when not is_nil(workspace_id),
    do: where(query, [e], e.workspace_id == ^workspace_id)

  defp maybe_filter_workspace(query, _), do: query
end
