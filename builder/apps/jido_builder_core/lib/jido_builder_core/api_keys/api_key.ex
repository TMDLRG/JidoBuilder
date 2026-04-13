defmodule JidoBuilderCore.ApiKeys.ApiKey do
  use JidoBuilderCore.Schema

  schema "api_keys" do
    field(:name, :string)
    field(:key_hash, :string)
    field(:key_prefix, :string)
    field(:status, :string, default: "active")
    field(:rate_limit, :integer, default: 100)
    field(:last_used_at, :utc_datetime_usec)

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)

    timestamps()
  end

  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:workspace_id, :name, :key_hash, :key_prefix, :status, :rate_limit, :last_used_at])
    |> validate_required([:workspace_id, :name, :key_hash, :key_prefix])
    |> unique_constraint(:key_hash)
  end
end
