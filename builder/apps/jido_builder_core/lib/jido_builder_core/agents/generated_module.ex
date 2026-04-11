defmodule JidoBuilderCore.Agents.GeneratedModule do
  use JidoBuilderCore.Schema

  schema "generated_modules" do
    field(:module_name, :string)
    field(:source_hash, :string)
    field(:file_path, :string)
    field(:compiled_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)
    belongs_to(:template, JidoBuilderCore.Templates.Template)
    belongs_to(:workflow, JidoBuilderCore.Workflows.Workflow)

    timestamps()
  end

  def changeset(generated_module, attrs) do
    generated_module
    |> cast(attrs, [
      :workspace_id,
      :template_id,
      :workflow_id,
      :module_name,
      :source_hash,
      :file_path,
      :compiled_at,
      :metadata
    ])
    |> validate_required([:workspace_id, :module_name, :source_hash])
    |> unique_constraint(:module_name)
  end
end
