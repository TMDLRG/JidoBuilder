defmodule JidoBuilderCore.Webhooks.DeliveryLog do
  @moduledoc "Schema for webhook delivery attempt tracking."
  use Ecto.Schema
  import Ecto.Changeset

  schema "webhook_delivery_logs" do
    field :webhook_id, :integer
    field :event_type, :string
    field :status, :string, default: "pending"
    field :details, :map, default: %{}

    timestamps()
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:webhook_id, :event_type, :status, :details])
    |> validate_required([:webhook_id, :event_type, :status])
    |> validate_inclusion(:status, ~w(pending delivered failed))
  end
end
