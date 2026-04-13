defmodule JidoBuilderCore.Repo.Migrations.CreateApiKeys do
  use Ecto.Migration

  def change do
    create table(:api_keys) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :key_hash, :string, null: false
      add :key_prefix, :string, null: false
      add :status, :string, null: false, default: "active"
      add :rate_limit, :integer, null: false, default: 100
      add :last_used_at, :utc_datetime_usec

      timestamps()
    end

    create unique_index(:api_keys, [:key_hash])
    create index(:api_keys, [:workspace_id])
  end
end
