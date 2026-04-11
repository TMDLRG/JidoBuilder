defmodule JidoBuilderCore.Repo.Migrations.AddCompileAttempts do
  use Ecto.Migration

  def change do
    create table(:compile_attempts) do
      add :workspace_id, references(:workspaces, on_delete: :nilify_all)
      add :template_id, references(:templates, on_delete: :nilify_all)
      add :status, :text, null: false
      add :request, :map, null: false, default: %{}
      add :diagnostics, :map, null: false, default: %{}
      add :generated_files, {:array, :text}, null: false, default: []

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:compile_attempts, [:workspace_id])
    create index(:compile_attempts, [:template_id])
    create index(:compile_attempts, [:inserted_at])
  end
end
