defmodule JidoBuilderCore.Templates.TemplateStateField do
  use JidoBuilderCore.Schema

  schema "template_state_fields" do
    field(:field_name, :string)
    field(:field_type, :string)
    field(:required, :boolean, default: false)
    field(:default_value, :map, default: %{})

    belongs_to(:template, JidoBuilderCore.Templates.Template)

    timestamps()
  end

  def changeset(template_state_field, attrs) do
    template_state_field
    |> cast(attrs, [:template_id, :field_name, :field_type, :required, :default_value])
    |> validate_required([:template_id, :field_name, :field_type])
  end
end
