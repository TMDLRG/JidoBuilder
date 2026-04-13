defmodule JidoBuilderCore.Repo.Migrations.CreateTemplateGenerativeModels do
  use Ecto.Migration

  def change do
    create table(:template_generative_models) do
      add :template_id, references(:templates, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :description, :text
      add :matrices, :map, null: false, default: %{}
      add :preferences, :map, null: false, default: %{}
      add :priors, :map, null: false, default: %{}
      add :policies, :map, null: false, default: "[]"
      add :config, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:template_generative_models, [:template_id])
  end
end
