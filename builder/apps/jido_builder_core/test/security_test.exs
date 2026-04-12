defmodule JidoBuilderCore.SecurityTest do
  use ExUnit.Case, async: false

  alias JidoBuilderCore.Agents
  alias JidoBuilderCore.Repo
  alias JidoBuilderCore.Security

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ok
  end

  test "persists encrypted ciphertext and only decrypts for runtime access" do
    {:ok, workspace} =
      Agents.create_workspace(%{name: "Security Workspace", slug: unique_slug()}, "test-suite")

    {:ok, integration} =
      Security.create_integration(
        %{
          workspace_id: workspace.id,
          name: "Stripe",
          provider: "stripe",
          status: "active",
          config: %{api_key: "sk_live_123", nested: %{secret: "abc"}}
        },
        "test-suite"
      )

    {:ok, secret} =
      Security.write_secret(
        %{
          workspace_id: workspace.id,
          integration_id: integration.id,
          name: "stripe_api_key",
          value: "sk_live_123"
        },
        "test-suite"
      )

    {:ok, %{rows: [[stored_ciphertext]]}} =
      Ecto.Adapters.SQL.query(Repo, "SELECT encrypted_value FROM secrets WHERE id = ?", [
        secret.id
      ])

    refute stored_ciphertext == "sk_live_123"

    {:ok, runtime_secret} = Security.get_secret_for_runtime(secret.id)
    assert runtime_secret.encrypted_value == "sk_live_123"
  end

  test "returns redacted values for UI views" do
    {:ok, workspace} =
      Agents.create_workspace(%{name: "Redaction Workspace", slug: unique_slug()}, "test-suite")

    {:ok, integration} =
      Security.create_integration(
        %{
          workspace_id: workspace.id,
          name: "OpenAI",
          provider: "openai",
          status: "active",
          config: %{api_key: "super-secret", options: [%{token: "nested-secret"}]}
        },
        "test-suite"
      )

    {:ok, secret} =
      Security.write_secret(
        %{
          workspace_id: workspace.id,
          integration_id: integration.id,
          name: "api_key",
          value: "super-secret"
        },
        "test-suite"
      )

    {:ok, ui_secret} = Security.get_secret_for_ui(secret.id)
    assert ui_secret.value == "[REDACTED]"

    {:ok, ui_integration} = Security.get_integration_for_ui(integration.id)
    # Keys are strings because Cloak.Ecto.Map round-trips through Jason,
    # which decodes JSON objects to string-keyed maps (intentionally —
    # using keys: :atoms would enable attacker-controlled atom DoS).
    assert ui_integration.config == %{
      "api_key" => "[REDACTED]",
      "options" => [%{"token" => "[REDACTED]"}]
    }

    inspected_secret = inspect(secret)
    refute String.contains?(inspected_secret, "super-secret")

    inspected_integration = inspect(integration)
    refute String.contains?(inspected_integration, "super-secret")
  end

  defp unique_slug, do: "workspace-#{System.unique_integer([:positive])}"
end
