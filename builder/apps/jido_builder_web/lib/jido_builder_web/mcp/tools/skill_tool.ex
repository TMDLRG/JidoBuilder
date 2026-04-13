defmodule JidoBuilderWeb.MCP.Tools.SkillTool do
  @moduledoc "MCP tool: jido_skill — list, get, create skills."

  alias JidoBuilderRuntime.Skills.SkillRegistry

  def call(%{"action" => "help"}, _ctx), do: {:ok, help_text()}

  def call(%{"action" => "list"}, _ctx) do
    {:ok, SkillRegistry.list()}
  end

  def call(%{"action" => "get", "slug" => slug}, _ctx) do
    case SkillRegistry.get(slug) do
      nil -> {:error, "Skill not found: #{slug}"}
      skill -> {:ok, skill}
    end
  end

  def call(%{"action" => "categories"}, _ctx) do
    {:ok, SkillRegistry.categories()}
  end

  def call(%{"action" => "by_category", "category" => cat}, _ctx) do
    {:ok, SkillRegistry.list_by_category(cat)}
  end

  def call(_, _), do: {:ok, help_text()}

  defp help_text do
    """
    jido_skill — Manage skills

    Actions:
      list              — List all pre-built skills
      get {slug}        — Get skill details by slug
      categories        — List skill categories
      by_category {cat} — List skills in a category
      help              — Show this help
    """
  end
end
