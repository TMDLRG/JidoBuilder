defmodule JidoBuilderCore.ApiKeys do
  @moduledoc """
  API key management: generation, validation, rotation.
  """
  import Ecto.Query

  alias JidoBuilderCore.{Audit, Repo}
  alias JidoBuilderCore.ApiKeys.ApiKey

  @prefix_length 8
  @key_length 32

  @doc """
  Generates a new API key for a workspace. Returns `{:ok, api_key, raw_key}`
  where `raw_key` is the plaintext key shown once to the user.
  """
  @spec generate(pos_integer(), String.t(), String.t()) ::
          {:ok, ApiKey.t(), String.t()} | {:error, Ecto.Changeset.t()}
  def generate(workspace_id, name, actor) do
    raw_key = :crypto.strong_rand_bytes(@key_length) |> Base.url_encode64(padding: false)
    key_hash = hash_key(raw_key)
    key_prefix = String.slice(raw_key, 0, @prefix_length)

    attrs = %{
      workspace_id: workspace_id,
      name: name,
      key_hash: key_hash,
      key_prefix: key_prefix,
      status: "active"
    }

    case %ApiKey{} |> ApiKey.changeset(attrs) |> Repo.insert() do
      {:ok, api_key} ->
        Audit.log(actor, "api_keys.generate", api_key, %{})
        {:ok, api_key, raw_key}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc "Validates a raw API key. Returns the ApiKey record if valid and active."
  @spec validate(String.t()) :: {:ok, ApiKey.t()} | {:error, :invalid | :revoked}
  def validate(raw_key) when is_binary(raw_key) do
    key_hash = hash_key(raw_key)

    case Repo.one(from k in ApiKey, where: k.key_hash == ^key_hash) do
      nil -> {:error, :invalid}
      %ApiKey{status: "revoked"} -> {:error, :revoked}
      %ApiKey{status: "active"} = key -> {:ok, key}
      _ -> {:error, :invalid}
    end
  end

  @doc "Revokes an API key."
  @spec revoke(pos_integer(), String.t()) :: {:ok, ApiKey.t()} | {:error, term()}
  def revoke(api_key_id, actor) do
    case Repo.get(ApiKey, api_key_id) do
      nil ->
        {:error, :not_found}

      key ->
        key
        |> ApiKey.changeset(%{status: "revoked"})
        |> Repo.update()
        |> case do
          {:ok, updated} ->
            Audit.log(actor, "api_keys.revoke", updated, %{})
            {:ok, updated}

          error ->
            error
        end
    end
  end

  @doc "Lists API keys for a workspace (hides key_hash)."
  @spec list(pos_integer()) :: [ApiKey.t()]
  def list(workspace_id) do
    ApiKey
    |> where([k], k.workspace_id == ^workspace_id)
    |> order_by([k], desc: k.inserted_at)
    |> Repo.all()
  end

  @doc "Updates last_used_at timestamp."
  def touch(api_key_id) do
    from(k in ApiKey, where: k.id == ^api_key_id)
    |> Repo.update_all(set: [last_used_at: DateTime.utc_now()])
  end

  defp hash_key(raw_key), do: :crypto.hash(:sha256, raw_key) |> Base.encode16(case: :lower)
end
