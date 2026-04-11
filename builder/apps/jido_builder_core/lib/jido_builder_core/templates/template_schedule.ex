defmodule JidoBuilderCore.Templates.TemplateSchedule do
  use JidoBuilderCore.Schema

  schema "template_schedules" do
    field(:name, :string)
    field(:cron, :string)
    field(:timezone, :string)
    field(:enabled, :boolean, default: true)
    field(:metadata, :map, default: %{})

    belongs_to(:template, JidoBuilderCore.Templates.Template)

    timestamps()
  end

  def changeset(template_schedule, attrs) do
    template_schedule
    |> cast(attrs, [:template_id, :name, :cron, :timezone, :enabled, :metadata])
    |> validate_required([:template_id, :name, :cron])
  end
end
