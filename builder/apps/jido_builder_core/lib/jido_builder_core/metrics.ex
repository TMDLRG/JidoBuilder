defmodule JidoBuilderCore.Metrics do
  @moduledoc "Aggregated time-series metrics for the Metrics Dashboard."

  import Ecto.Query

  alias JidoBuilderCore.Observability.{DirectiveLog, SignalLog}
  alias JidoBuilderCore.Repo

  @doc "Returns hourly signal counts for the last N hours."
  def signals_per_hour(workspace_id, hours \\ 24) do
    cutoff = DateTime.utc_now() |> DateTime.add(-hours * 3600, :second)

    from(s in SignalLog,
      where: s.workspace_id == ^workspace_id and s.inserted_at >= ^cutoff,
      group_by: fragment("strftime('%Y-%m-%d %H:00', ?)", s.inserted_at),
      order_by: fragment("strftime('%Y-%m-%d %H:00', ?)", s.inserted_at),
      select: %{
        hour: fragment("strftime('%Y-%m-%d %H:00', ?)", s.inserted_at),
        count: count(s.id)
      }
    )
    |> Repo.all()
  end

  @doc "Returns hourly error counts for the last N hours."
  def errors_per_hour(workspace_id, hours \\ 24) do
    cutoff = DateTime.utc_now() |> DateTime.add(-hours * 3600, :second)

    from(d in DirectiveLog,
      where:
        d.workspace_id == ^workspace_id and
          d.inserted_at >= ^cutoff and
          d.directive_type == "runtime.error",
      group_by: fragment("strftime('%Y-%m-%d %H:00', ?)", d.inserted_at),
      order_by: fragment("strftime('%Y-%m-%d %H:00', ?)", d.inserted_at),
      select: %{
        hour: fragment("strftime('%Y-%m-%d %H:00', ?)", d.inserted_at),
        count: count(d.id)
      }
    )
    |> Repo.all()
  end
end
