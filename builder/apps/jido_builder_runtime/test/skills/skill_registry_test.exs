defmodule JidoBuilderRuntime.Skills.SkillRegistryTest do
  @moduledoc "Epic 3.5 — Skill Registry tests."
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.Skills.SkillRegistry

  describe "list/0" do
    test "returns 5 pre-built skills" do
      skills = SkillRegistry.list()
      assert length(skills) == 5
    end

    test "each skill has required fields" do
      for skill <- SkillRegistry.list() do
        assert is_binary(skill.slug)
        assert is_binary(skill.name)
        assert is_binary(skill.description)
        assert is_binary(skill.category)
        assert is_list(skill.action_slugs)
        assert is_binary(skill.system_prompt_fragment)
      end
    end
  end

  describe "get/1" do
    test "returns skill by slug" do
      skill = SkillRegistry.get("research")
      assert skill.name == "Research"
      assert "web_fetch" in skill.action_slugs
    end

    test "returns nil for unknown slug" do
      assert SkillRegistry.get("nonexistent") == nil
    end
  end

  describe "list_by_category/1" do
    test "filters by category" do
      dev = SkillRegistry.list_by_category("development")
      assert length(dev) == 1
      assert List.first(dev).slug == "code_review"
    end
  end

  describe "categories/0" do
    test "returns unique categories" do
      cats = SkillRegistry.categories()
      assert length(cats) > 0
      assert Enum.all?(cats, &is_binary/1)
    end
  end
end
