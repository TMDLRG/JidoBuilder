defmodule JidoBuilderCore.Repo.Migrations.CreateWebhooks do
  use Ecto.Migration

  def change do
    create table(:webhooks) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :url, :string, null: false
      add :events, :string, null: false
      add :status, :string, null: false, default: "active"
      add :secret, :string
      add :metadata, :map, default: %{}

      timestamps()
    end

    create index(:webhooks, [:workspace_id])
  end
end
