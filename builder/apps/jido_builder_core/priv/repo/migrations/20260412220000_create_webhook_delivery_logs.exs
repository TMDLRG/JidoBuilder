defmodule JidoBuilderCore.Repo.Migrations.CreateWebhookDeliveryLogs do
  use Ecto.Migration

  def change do
    create table(:webhook_delivery_logs) do
      add :webhook_id, references(:webhooks, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :details, :map, default: %{}

      timestamps()
    end

    create index(:webhook_delivery_logs, [:webhook_id])
    create index(:webhook_delivery_logs, [:status])
  end
end
