defmodule JidoBuilderCore.Repo.Migrations.CreateConversationMessages do
  use Ecto.Migration

  def change do
    create table(:conversation_messages) do
      add :template_id, references(:templates, on_delete: :delete_all), null: false
      add :conversation_id, :string, null: false
      add :role, :string, null: false
      add :content, :text
      add :tool_data, :map, default: %{}

      timestamps()
    end

    create index(:conversation_messages, [:template_id, :conversation_id])
    create index(:conversation_messages, [:conversation_id])
  end
end
