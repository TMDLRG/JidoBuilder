defmodule JidoBuilderCore.Repo.Migrations.CreateTemplateLlmConfigs do
  use Ecto.Migration

  def change do
    create table(:template_llm_configs) do
      add :template_id, references(:templates, on_delete: :delete_all), null: false
      add :provider, :text, null: false
      add :model, :text, null: false
      add :system_prompt, :text
      add :temperature, :float, default: 0.7
      add :max_tokens, :integer, default: 1024
      add :tool_whitelist, :map, null: false, default: "[]"
      add :config, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:template_llm_configs, [:template_id])
  end
end
