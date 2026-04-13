defmodule JidoBuilderCore.Webhooks.Webhook do
  use JidoBuilderCore.Schema

  schema "webhooks" do
    field(:name, :string)
    field(:url, :string)
    field(:events, :string)
    field(:status, :string, default: "active")
    field(:secret, :string)
    field(:metadata, :map, default: %{})

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)

    timestamps()
  end

  def changeset(webhook, attrs) do
    webhook
    |> cast(attrs, [:workspace_id, :name, :url, :events, :status, :secret, :metadata])
    |> validate_required([:workspace_id, :name, :url, :events])
  end
end
