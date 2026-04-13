defmodule JidoBuilderCore.Repo.Migrations.CreateNotebooks do
  use Ecto.Migration

  def change do
    create table(:notebooks) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :description, :text
      add :cells, :map, null: false, default: "[]"
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:notebooks, [:workspace_id])
  end
end
