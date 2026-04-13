defmodule JidoBuilderCore.Repo.Migrations.CreateDeadLetterQueue do
  use Ecto.Migration

  def change do
    create table(:dead_letter_queue) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :agent_name, :string, null: false
      add :signal_type, :string, null: false
      add :payload, :map, default: %{}
      add :error, :string
      add :status, :string, null: false, default: "pending"

      timestamps()
    end

    create index(:dead_letter_queue, [:workspace_id])
    create index(:dead_letter_queue, [:status])
  end
end
