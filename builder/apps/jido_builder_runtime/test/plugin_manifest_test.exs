defmodule JidoBuilderRuntime.PluginManifestTest do
  @moduledoc "Story 8.3 — Plugin manifest validation."
  use ExUnit.Case, async: false

  alias JidoBuilderRuntime.PluginManifest

  test "valid manifest parses correctly" do
    manifest = %{
      "name" => "my-plugin",
      "version" => "1.0.0",
      "description" => "A test plugin",
      "entry_module" => "MyPlugin",
      "actions" => ["action_one", "action_two"]
    }

    assert {:ok, parsed} = PluginManifest.validate(manifest)
    assert parsed.name == "my-plugin"
    assert parsed.version == "1.0.0"
    assert length(parsed.actions) == 2
  end

  test "manifest with missing required fields rejected" do
    assert {:error, _} = PluginManifest.validate(%{})
    assert {:error, _} = PluginManifest.validate(%{"name" => "test"})
  end

  test "manifest with invalid version format rejected" do
    manifest = %{
      "name" => "test",
      "version" => "not-a-version",
      "description" => "Test",
      "entry_module" => "Test"
    }

    assert {:error, _} = PluginManifest.validate(manifest)
  end
end
