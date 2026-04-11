defmodule JidoBuilderCore.Security.Secret do
  use JidoBuilderCore.Schema

  schema "secrets" do
    field(:name, :string)
    field(:encrypted_value, :string)
    field(:key_id, :string)
    field(:metadata, :map, default: %{})

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)
    belongs_to(:integration, JidoBuilderCore.Security.Integration)

    timestamps()
  end

  def changeset(secret, attrs) do
    secret
    |> cast(attrs, [:workspace_id, :integration_id, :name, :encrypted_value, :key_id, :metadata])
    |> validate_required([:workspace_id, :name, :encrypted_value])
  end
end
