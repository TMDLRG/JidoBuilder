defmodule JidoBuilderCore.Security do
  import Ecto.Query

  alias JidoBuilderCore.Audit
  alias JidoBuilderCore.Repo
  alias JidoBuilderCore.Security.{Integration, Secret}

  @redacted "[REDACTED]"

  def create_integration(attrs, actor),
    do: insert_with_audit(Integration, attrs, actor, "security.integrations.create")

  def create_secret(attrs, actor),
    do: insert_with_audit(Secret, attrs, actor, "security.secrets.create")

  def write_secret(attrs, actor) do
    attrs
    |> normalize_secret_attrs()
    |> create_secret(actor)
  end

  def get_secret_for_ui(secret_id) do
    case Repo.get(Secret, secret_id) do
      nil -> {:error, :not_found}
      secret -> {:ok, redacted_secret(secret)}
    end
  end

  def get_secret_for_runtime(secret_id) do
    case Repo.get(Secret, secret_id) do
      nil -> {:error, :not_found}
      secret -> {:ok, secret}
    end
  end

  def get_integration_for_ui(integration_id) do
    case Repo.get(Integration, integration_id) do
      nil ->
        {:error, :not_found}

      integration ->
        {:ok,
         %{
           id: integration.id,
           workspace_id: integration.workspace_id,
           name: integration.name,
           provider: integration.provider,
           status: integration.status,
           config: redact_map(integration.config)
         }}
    end
  end

  def get_integration_for_runtime(integration_id) do
    case Repo.get(Integration, integration_id) do
      nil -> {:error, :not_found}
      integration -> {:ok, integration}
    end
  end

  def list_secrets_for_ui(filters \\ %{}) do
    Secret
    |> maybe_filter_workspace(filters)
    |> maybe_filter_integration(filters)
    |> Repo.all()
    |> Enum.map(&redacted_secret/1)
  end

  defp maybe_filter_workspace(query, %{workspace_id: workspace_id}) when not is_nil(workspace_id),
    do: where(query, [s], s.workspace_id == ^workspace_id)

  defp maybe_filter_workspace(query, _), do: query

  defp maybe_filter_integration(query, %{integration_id: integration_id})
       when not is_nil(integration_id),
       do: where(query, [s], s.integration_id == ^integration_id)

  defp maybe_filter_integration(query, _), do: query

  defp normalize_secret_attrs(%{value: value} = attrs),
    do: attrs |> Map.put(:encrypted_value, value) |> Map.delete(:value)

  defp normalize_secret_attrs(attrs) when is_map(attrs), do: attrs

  defp redacted_secret(secret) do
    %{
      id: secret.id,
      workspace_id: secret.workspace_id,
      integration_id: secret.integration_id,
      name: secret.name,
      value: @redacted,
      key_id: secret.key_id,
      metadata: secret.metadata,
      inserted_at: secret.inserted_at,
      updated_at: secret.updated_at
    }
  end

  defp redact_map(map) when is_map(map), do: Map.new(map, fn {k, v} -> {k, redact_value(v)} end)

  defp redact_value(value) when is_map(value), do: redact_map(value)
  defp redact_value(value) when is_list(value), do: Enum.map(value, &redact_value/1)
  defp redact_value(_value), do: @redacted

  defp insert_with_audit(schema, attrs, actor, action) do
    struct(schema)
    |> schema.changeset(attrs)
    |> Repo.insert()
    |> maybe_audit(actor, action)
  end

  defp maybe_audit({:ok, record} = ok, actor, action) do
    _ = Audit.log(actor, action, record, %{})
    ok
  end

  defp maybe_audit(error, _actor, _action), do: error
end
