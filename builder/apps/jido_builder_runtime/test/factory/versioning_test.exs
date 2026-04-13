defmodule JidoBuilderRuntime.Factory.VersioningTest do
  @moduledoc "Epic 4.3 — Versioning tests."
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.Factory.Versioning

  defp sample_config do
    %{
      name: "test_agent",
      routes: [%{signal: "user.query", action: "Echo"}],
      settings: %{max_retries: 3, timeout: 5000}
    }
  end

  describe "create_version/2" do
    test "creates a version snapshot" do
      version = Versioning.create_version(sample_config(), "Initial version")

      assert version.version > 0
      assert version.config_snapshot == sample_config()
      assert version.changelog == "Initial version"
      assert %DateTime{} = version.created_at
    end

    test "snapshot is a deep copy" do
      config = sample_config()
      version = Versioning.create_version(config, "test")

      # Modifying original should not affect snapshot
      assert version.config_snapshot.name == "test_agent"
    end
  end

  describe "diff/2" do
    test "detects added keys" do
      old = %{a: 1, b: 2}
      new = %{a: 1, b: 2, c: 3}

      result = Versioning.diff(old, new)
      assert :c in result.added
      assert result.removed == []
    end

    test "detects removed keys" do
      old = %{a: 1, b: 2, c: 3}
      new = %{a: 1, b: 2}

      result = Versioning.diff(old, new)
      assert :c in result.removed
    end

    test "detects changed values" do
      old = %{a: 1, b: 2}
      new = %{a: 1, b: 99}

      result = Versioning.diff(old, new)
      assert :b in result.changed
      assert :a in result.unchanged
    end

    test "identical configs show no changes" do
      config = %{a: 1, b: 2}
      result = Versioning.diff(config, config)

      assert result.added == []
      assert result.removed == []
      assert result.changed == []
    end
  end

  describe "rollback/1" do
    test "restores config from version" do
      config = sample_config()
      version = Versioning.create_version(config, "v1")

      restored = Versioning.rollback(version)
      assert restored == config
    end
  end

  describe "clone/2" do
    test "clones with overrides" do
      config = sample_config()
      cloned = Versioning.clone(config, %{name: "cloned_agent"})

      assert cloned.name == "cloned_agent"
      assert cloned.routes == config.routes
    end

    test "clone without overrides is identical" do
      config = sample_config()
      cloned = Versioning.clone(config)

      assert cloned == config
    end
  end
end
