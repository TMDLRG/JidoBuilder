defmodule JidoBuilderRuntime.DynamicPod do
  @moduledoc """
  Builds pod runtime metadata from DB-backed template and schedule rows.
  """

  import Ecto.Query

  alias JidoBuilderCore.Repo
  alias JidoBuilderCore.Templates.TemplateSchedule
  alias JidoBuilderRuntime.Error

  @type pod_config :: %{
          template_id: pos_integer(),
          schedules: [map()]
        }

  @spec config_for_template(pos_integer()) :: {:ok, pod_config()} | {:error, Error.t()}
  def config_for_template(template_id) when is_integer(template_id) do
    schedules =
      TemplateSchedule
      |> where([s], s.template_id == ^template_id and s.enabled == true)
      |> Repo.all()
      |> Enum.map(fn row ->
        %{
          name: row.name,
          cron: row.cron,
          timezone: row.timezone,
          metadata: row.metadata || %{}
        }
      end)

    {:ok, %{template_id: template_id, schedules: schedules}}
  rescue
    error ->
      {:error,
       Error.new(:pod_config_failed, "unable to load pod config", %{
         reason: Exception.message(error)
       })}
  end
end
