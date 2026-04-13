defmodule JidoBuilderWeb.MCP.Tools.NewToolsTest do
  @moduledoc "Epic 6.1 — New MCP tools tests."
  use ExUnit.Case, async: true

  alias JidoBuilderWeb.MCP.Tools.{
    FactoryTool,
    SkillTool,
    LlmTool,
    ActiveInferenceTool,
    NotebookTool,
    LibraryTool,
    SolutionTool
  }

  @ctx %{workspace_id: 1}

  describe "FactoryTool" do
    test "help action" do
      {:ok, text} = FactoryTool.call(%{"action" => "help"}, @ctx)
      assert is_binary(text)
      assert String.contains?(text, "compose")
    end

    test "clone action" do
      {:ok, result} = FactoryTool.call(%{
        "action" => "clone",
        "config" => %{"name" => "original"},
        "overrides" => %{"name" => "cloned"}
      }, @ctx)
      assert result["name"] == "cloned"
    end

    test "diff action" do
      {:ok, result} = FactoryTool.call(%{
        "action" => "diff",
        "old" => %{"a" => 1},
        "new" => %{"a" => 1, "b" => 2}
      }, @ctx)
      assert "b" in result.added
    end

    test "deploy_team action" do
      {:ok, result} = FactoryTool.call(%{"action" => "deploy_team", "solution" => "help_desk"}, @ctx)
      assert result.status == :deployed
    end
  end

  describe "SkillTool" do
    test "list action" do
      {:ok, skills} = SkillTool.call(%{"action" => "list"}, @ctx)
      assert length(skills) == 5
    end

    test "get action" do
      {:ok, skill} = SkillTool.call(%{"action" => "get", "slug" => "research"}, @ctx)
      assert skill.name == "Research"
    end

    test "categories action" do
      {:ok, cats} = SkillTool.call(%{"action" => "categories"}, @ctx)
      assert is_list(cats)
    end
  end

  describe "LlmTool" do
    test "providers action" do
      {:ok, providers} = LlmTool.call(%{"action" => "providers"}, @ctx)
      assert length(providers) == 3
    end

    test "configure action" do
      {:ok, result} = LlmTool.call(%{
        "action" => "configure",
        "provider" => "anthropic",
        "model" => "claude-sonnet-4-20250514"
      }, @ctx)
      assert result.configured == true
    end
  end

  describe "ActiveInferenceTool" do
    test "presets action" do
      {:ok, presets} = ActiveInferenceTool.call(%{"action" => "presets"}, @ctx)
      assert length(presets) == 4
    end

    test "create_model action" do
      {:ok, result} = ActiveInferenceTool.call(%{"action" => "create_model", "preset" => "forager"}, @ctx)
      assert result.created == true
      assert result.num_states == 2
    end

    test "evaluate action" do
      {:ok, result} = ActiveInferenceTool.call(%{
        "action" => "evaluate",
        "preset" => "thermostat",
        "observation" => 0
      }, @ctx)
      assert is_list(result.posterior)
      assert is_float(result.entropy)
      assert is_list(result.efe_scores)
    end
  end

  describe "NotebookTool" do
    test "create action" do
      {:ok, result} = NotebookTool.call(%{"action" => "create", "name" => "Test"}, @ctx)
      assert result.created == true
    end

    test "run_cell action" do
      NotebookTool.call(%{"action" => "create"}, @ctx)
      {:ok, result} = NotebookTool.call(%{"action" => "run_cell", "code" => "1 + 2"}, @ctx)
      assert result.result == "3"
      assert result.status == "ok"
    end

    test "list_cells action" do
      NotebookTool.call(%{"action" => "create"}, @ctx)
      NotebookTool.call(%{"action" => "run_cell", "code" => "42"}, @ctx)
      {:ok, result} = NotebookTool.call(%{"action" => "list_cells"}, @ctx)
      assert result.count >= 1
    end

    test "export action" do
      NotebookTool.call(%{"action" => "create"}, @ctx)
      NotebookTool.call(%{"action" => "run_cell", "code" => "x = 1"}, @ctx)
      {:ok, result} = NotebookTool.call(%{"action" => "export", "module_name" => "MyMod"}, @ctx)
      assert String.contains?(result.code, "defmodule MyMod")
    end

    test "reset action" do
      {:ok, result} = NotebookTool.call(%{"action" => "reset"}, @ctx)
      assert result.reset == true
    end
  end

  describe "LibraryTool" do
    test "browse_actions action" do
      {:ok, result} = LibraryTool.call(%{"action" => "browse_actions"}, @ctx)
      assert result.count > 50
    end

    test "browse_skills action" do
      {:ok, skills} = LibraryTool.call(%{"action" => "browse_skills"}, @ctx)
      assert length(skills) == 5
    end

    test "browse_solutions action" do
      {:ok, solutions} = LibraryTool.call(%{"action" => "browse_solutions"}, @ctx)
      assert length(solutions) == 5
    end

    test "search action" do
      {:ok, result} = LibraryTool.call(%{"action" => "search", "query" => "echo"}, @ctx)
      assert result.count > 0
    end

    test "categories action" do
      {:ok, result} = LibraryTool.call(%{"action" => "categories"}, @ctx)
      assert is_list(result.action_categories)
    end
  end

  describe "SolutionTool" do
    test "list action" do
      {:ok, solutions} = SolutionTool.call(%{"action" => "list"}, @ctx)
      assert length(solutions) == 5
    end

    test "get action" do
      {:ok, solution} = SolutionTool.call(%{"action" => "get", "slug" => "help_desk"}, @ctx)
      assert solution.name == "Help Desk"
    end

    test "deploy action" do
      {:ok, result} = SolutionTool.call(%{"action" => "deploy", "slug" => "help_desk"}, @ctx)
      assert result.status == "deployed"
    end

    test "get unknown returns error" do
      {:error, _} = SolutionTool.call(%{"action" => "get", "slug" => "nonexistent"}, @ctx)
    end
  end
end
