defmodule JidoBuilderCore.Repo.Migrations.CreateWorkflowEdges do
  use Ecto.Migration

  def change do
    create table(:workflow_edges) do
      add :workflow_id, references(:workflows, on_delete: :delete_all), null: false
      add :source_step_id, references(:workflow_steps, on_delete: :delete_all), null: false
      add :target_step_id, references(:workflow_steps, on_delete: :delete_all), null: false
      add :label, :string
      add :condition, :map, default: %{}

      timestamps()
    end

    create index(:workflow_edges, [:workflow_id])
    create index(:workflow_edges, [:source_step_id])
    create index(:workflow_edges, [:target_step_id])
  end
end
