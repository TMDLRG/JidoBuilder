defmodule JidoBuilderRuntime.Skills.SolutionCatalogTest do
  @moduledoc "Epic 3.8 — Solution catalog tests."
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.Skills.SolutionCatalog

  describe "list/0" do
    test "returns 5 solutions" do
      solutions = SolutionCatalog.list()
      assert length(solutions) == 5
    end

    test "each solution has required fields" do
      for sol <- SolutionCatalog.list() do
        assert is_binary(sol.slug)
        assert is_binary(sol.name)
        assert is_binary(sol.description)
        assert is_binary(sol.category)
        assert is_list(sol.template_slugs)
        assert is_list(sol.skill_slugs)
      end
    end
  end

  describe "get/1" do
    test "returns solution by slug" do
      sol = SolutionCatalog.get("help_desk")
      assert sol.name == "Help Desk"
    end

    test "returns nil for unknown" do
      assert SolutionCatalog.get("nonexistent") == nil
    end
  end

  describe "list_by_category/1" do
    test "filters by category" do
      eng = SolutionCatalog.list_by_category("engineering")
      assert length(eng) == 1
    end
  end
end
