defmodule Mix.Tasks.JidoBuilder.RotateCloakKey do
  @shortdoc "Re-encrypts all Cloak-encrypted rows with a new vault key"

  @moduledoc """
  Rotates the Cloak encryption key for all encrypted schemas.

  ## Usage

      mix jido_builder.rotate_cloak_key \\
        --new-key <base64-encoded-32-byte-key> \\
        --new-tag <cipher-tag> \\
        --legacy-key <base64-encoded-32-byte-key> \\
        --legacy-tag <old-cipher-tag>

  ## Options

    * `--new-key`    — Base64-encoded bytes for the new default AES-256 key (required)
    * `--new-tag`    — Tag string for the new cipher (default: `"AES.GCM.V2"`)
    * `--legacy-key` — Base64-encoded bytes for the key currently in production (required)
    * `--legacy-tag` — Tag string for the legacy cipher (default: `"AES.GCM.V1"`)

  ## Rotation workflow

  1. Generate a new 32-byte key: `mix run -e "IO.puts Base.encode64(:crypto.strong_rand_bytes(32))"`
  2. Update your environment/secrets store with the new key value under
     `JIDO_BUILDER_CLOAK_KEY` but do NOT remove the old key yet.
  3. Run this task — it reconfigures the vault with V2 as default and V1 as
     retired, then rewrites every encrypted row so all ciphertext uses V2.
  4. Once the task completes, remove the legacy key from your secrets store.

  ## Schemas migrated

  - `JidoBuilderCore.Security.Secret`   (`:encrypted_value`)
  - `JidoBuilderCore.Security.Integration` (`:config`)
  """

  use Mix.Task

  @schemas [
    JidoBuilderCore.Security.Secret,
    JidoBuilderCore.Security.Integration
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [new_key: :string, new_tag: :string, legacy_key: :string, legacy_tag: :string]
      )

    new_key_b64 = Keyword.fetch!(opts, :new_key)
    legacy_key_b64 = Keyword.fetch!(opts, :legacy_key)
    new_tag = Keyword.get(opts, :new_tag, "AES.GCM.V2")
    legacy_tag = Keyword.get(opts, :legacy_tag, "AES.GCM.V1")

    Mix.Task.run("app.start", [])

    JidoBuilderCore.Vault.reconfigure(
      ciphers: [
        default:
          {Cloak.Ciphers.AES.GCM, tag: new_tag, key: Base.decode64!(new_key_b64)},
        retired:
          {Cloak.Ciphers.AES.GCM, tag: legacy_tag, key: Base.decode64!(legacy_key_b64)}
      ]
    )

    rotate(JidoBuilderCore.Repo, @schemas)
  end

  @doc """
  Re-encrypts all Cloak-typed fields in the given schemas using the vault's
  current default cipher.

  This is a SQLite-safe, single-process implementation (no row-level locks,
  no async tasks) that works correctly in both production and test sandbox
  environments.
  """
  def rotate(repo, schemas) when is_list(schemas) do
    Enum.each(schemas, fn schema ->
      Mix.shell().info("Rotating #{inspect(schema)}...")
      rotate_schema(repo, schema)
      Mix.shell().info("  done.")
    end)
  end

  defp rotate_schema(repo, schema) do
    fields = cloak_fields(schema)

    repo.all(schema)
    |> Enum.each(fn row ->
      changeset =
        Enum.reduce(fields, Ecto.Changeset.change(row), fn field, cs ->
          Ecto.Changeset.force_change(cs, field, Map.get(row, field))
        end)

      repo.update!(changeset)
    end)
  end

  defp cloak_fields(schema) do
    schema.__schema__(:fields)
    |> Enum.filter(fn field ->
      type = schema.__schema__(:type, field)
      cloak_type?(type)
    end)
  end

  defp cloak_type?(type) when is_atom(type) do
    Code.ensure_loaded?(type) and function_exported?(type, :__cloak__, 0)
  end

  defp cloak_type?(_), do: false
end
