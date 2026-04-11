defmodule JidoBuilderCore.Codegen.CompileAttempt do
  use JidoBuilderCore.Schema

  @type t :: %__MODULE__{}

  schema "compile_attempts" do
    field(:status, :string)
    field(:request, :map, default: %{})
    field(:diagnostics, :map, default: %{})
    field(:generated_files, {:array, :string}, default: [])

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)
    belongs_to(:template, JidoBuilderCore.Templates.Template)

    timestamps(updated_at: false)
  end

  def changeset(attempt, attrs) do
    attempt
    |> cast(attrs, [
      :workspace_id,
      :template_id,
      :status,
      :request,
      :diagnostics,
      :generated_files
    ])
    |> validate_required([:status, :request])
  end
end
