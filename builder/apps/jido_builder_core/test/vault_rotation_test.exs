defmodule JidoBuilderCore.VaultRotationTest do
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, Repo, Security, Vault}

  # V1 key is the test default (from config/test.exs)
  @v1_key_b64 "ZmVkY2JhOTg3NjU0MzIxMGZlZGNiYTk4NzY1NDMyMTA="
  @v1_tag "AES.GCM.V1"

  # V2 key: 32 bytes of 0x02 — distinct from V1 to ensure re-encryption happened
  @v2_key_b64 Base.encode64(:binary.copy(<<2>>, 32))
  @v2_tag "AES.GCM.V2"

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    on_exit(fn ->
      Vault.reconfigure(
        ciphers: [
          default:
            {Cloak.Ciphers.AES.GCM,
             tag: @v1_tag, key: Base.decode64!(@v1_key_b64)}
        ]
      )
    end)

    :ok
  end

  test "rotate_cloak_key re-encrypts secrets with new key while preserving plaintext" do
    {:ok, workspace} =
      Agents.create_workspace(%{name: "Rotation WS", slug: unique_slug()}, "test")

    {:ok, secret} =
      Security.write_secret(
        %{workspace_id: workspace.id, name: "rotation_secret", value: "super-secret-value"},
        "test"
      )

    # Capture pre-rotation raw ciphertext bytes
    {:ok, %{rows: [[ciphertext_before]]}} =
      Ecto.Adapters.SQL.query(Repo, "SELECT encrypted_value FROM secrets WHERE id = ?", [
        secret.id
      ])

    # Switch vault to V2 as default; keep V1 as retired so existing rows can still be read
    Vault.reconfigure(
      ciphers: [
        default:
          {Cloak.Ciphers.AES.GCM, tag: @v2_tag, key: Base.decode64!(@v2_key_b64)},
        retired:
          {Cloak.Ciphers.AES.GCM, tag: @v1_tag, key: Base.decode64!(@v1_key_b64)}
      ]
    )

    # Run rotation — our SQLite-safe implementation (not Cloak.Ecto.Migrator)
    Mix.Tasks.JidoBuilder.RotateCloakKey.rotate(Repo, [JidoBuilderCore.Security.Secret])

    # Capture post-rotation raw ciphertext bytes
    {:ok, %{rows: [[ciphertext_after]]}} =
      Ecto.Adapters.SQL.query(Repo, "SELECT encrypted_value FROM secrets WHERE id = ?", [
        secret.id
      ])

    # The stored bytes must have changed (different encryption key used)
    refute ciphertext_before == ciphertext_after,
           "Expected ciphertext to change after key rotation, but it did not"

    # Plaintext must still be readable via the normal context function
    {:ok, runtime_secret} = Security.get_secret_for_runtime(secret.id)
    assert runtime_secret.encrypted_value == "super-secret-value"
  end

  defp unique_slug, do: "rot-ws-#{System.unique_integer([:positive])}"
end
