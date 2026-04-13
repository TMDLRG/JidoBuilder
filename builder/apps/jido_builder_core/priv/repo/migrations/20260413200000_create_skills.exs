defmodule JidoBuilderCore.Repo.Migrations.CreateSkills do
  use Ecto.Migration

  def change do
    create table(:skills) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :slug, :text, null: false
      add :description, :text
      add :category, :text
      add :action_slugs, :map, null: false, default: "[]"
      add :system_prompt_fragment, :text
      add :config, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:skills, [:workspace_id, :slug])
  end
end
