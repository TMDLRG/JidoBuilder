defmodule JidoBuilderCore.Security.Integration do
  use JidoBuilderCore.Schema

  schema "integrations" do
    field(:name, :string)
    field(:provider, :string)
    field(:status, :string)
    field(:config, :map, default: %{})

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)

    timestamps()
  end

  def changeset(integration, attrs) do
    integration
    |> cast(attrs, [:workspace_id, :name, :provider, :status, :config])
    |> validate_required([:workspace_id, :name, :provider, :status])
  end
end
