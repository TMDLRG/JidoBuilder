defmodule JidoBuilderCore.Templates.TemplateSensor do
  use JidoBuilderCore.Schema

  schema "templates_sensors" do
    field(:name, :string)
    field(:module, :string)
    field(:config, :map, default: %{})
    field(:enabled, :boolean, default: true)

    belongs_to(:template, JidoBuilderCore.Templates.Template)

    timestamps()
  end

  def changeset(template_sensor, attrs) do
    template_sensor
    |> cast(attrs, [:template_id, :name, :module, :config, :enabled])
    |> validate_required([:template_id, :name, :module])
  end
end
