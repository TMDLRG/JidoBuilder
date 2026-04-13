defmodule JidoBuilderCore.ApiKeysTest do
  @moduledoc "Story 10.1 — API keys context coverage."
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, ApiKeys, Repo}

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "apikeys-#{System.unique_integer()}", slug: "apikeys-#{System.unique_integer()}"},
        "test"
      )

    %{workspace: workspace}
  end

  test "generate creates an API key with raw token", %{workspace: ws} do
    {:ok, api_key, raw_key} = ApiKeys.generate(ws.id, "test-key", "test")

    assert api_key.name == "test-key"
    assert api_key.workspace_id == ws.id
    assert is_binary(raw_key)
    assert String.length(raw_key) > 20
  end

  test "validate returns key for valid raw token", %{workspace: ws} do
    {:ok, _api_key, raw_key} = ApiKeys.generate(ws.id, "val-key", "test")

    assert {:ok, key} = ApiKeys.validate(raw_key)
    assert key.name == "val-key"
  end

  test "validate returns error for invalid token" do
    assert {:error, _} = ApiKeys.validate("not-a-real-key-at-all")
  end

  test "revoke marks key as revoked", %{workspace: ws} do
    {:ok, api_key, raw_key} = ApiKeys.generate(ws.id, "rev-key", "test")

    assert {:ok, _} = ApiKeys.revoke(api_key.id, "test")
    assert {:error, _} = ApiKeys.validate(raw_key)
  end

  test "list returns all keys for workspace", %{workspace: ws} do
    {:ok, _, _} = ApiKeys.generate(ws.id, "list-key-1", "test")
    {:ok, _, _} = ApiKeys.generate(ws.id, "list-key-2", "test")

    keys = ApiKeys.list(ws.id)
    assert length(keys) >= 2
  end

  test "cannot validate a revoked key", %{workspace: ws} do
    {:ok, api_key, raw_key} = ApiKeys.generate(ws.id, "revoked-key", "test")
    {:ok, _} = ApiKeys.revoke(api_key.id, "test")

    assert {:error, _} = ApiKeys.validate(raw_key)
  end
end
