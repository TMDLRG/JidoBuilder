defmodule JidoBuilderCore.Templates.TemplateRoute do
  use JidoBuilderCore.Schema

  schema "template_routes" do
    field(:signal, :string)
    field(:target, :string)
    field(:action, :string)
    field(:opts, :map, default: %{})

    belongs_to(:template, JidoBuilderCore.Templates.Template)

    timestamps()
  end

  def changeset(template_route, attrs) do
    template_route
    |> cast(attrs, [:template_id, :signal, :target, :action, :opts])
    |> validate_required([:template_id, :signal, :target, :action])
  end
end
