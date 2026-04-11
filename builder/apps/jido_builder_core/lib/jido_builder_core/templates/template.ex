defmodule JidoBuilderCore.Templates.Template do
  use JidoBuilderCore.Schema

  schema "templates" do
    field(:name, :string)
    field(:slug, :string)
    field(:description, :string)
    field(:version, :string)
    field(:status, :string)
    field(:config, :map, default: %{})

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)
    belongs_to(:partition, JidoBuilderCore.Agents.Partition)

    has_many(:routes, JidoBuilderCore.Templates.TemplateRoute)
    has_many(:state_fields, JidoBuilderCore.Templates.TemplateStateField)
    has_many(:schedules, JidoBuilderCore.Templates.TemplateSchedule)
    has_many(:plugins, JidoBuilderCore.Templates.TemplatePlugin)
    has_many(:sensors, JidoBuilderCore.Templates.TemplateSensor)

    timestamps()
  end

  def changeset(template, attrs) do
    template
    |> cast(attrs, [
      :workspace_id,
      :partition_id,
      :name,
      :slug,
      :description,
      :version,
      :status,
      :config
    ])
    |> validate_required([:workspace_id, :name, :slug, :version, :status])
    |> unique_constraint(:slug, name: :templates_workspace_id_slug_index)
  end
end
