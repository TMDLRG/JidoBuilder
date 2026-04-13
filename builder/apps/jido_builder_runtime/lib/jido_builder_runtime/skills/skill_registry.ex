defmodule JidoBuilderRuntime.Skills.SkillRegistry do
  @moduledoc """
  Registry of pre-built skills.

  A Skill = {action_slugs, system_prompt_fragment} — metadata only, not a runtime concept.
  Skills are composable building blocks for agent templates.
  """

  @skills [
    %{
      slug: "research",
      name: "Research",
      description: "Web research and information gathering",
      category: "knowledge",
      action_slugs: ["web_fetch", "web_scrape", "search_web", "rss_fetch", "url_parse"],
      system_prompt_fragment: "You are a research assistant. Search the web, scrape pages, and compile findings into concise summaries."
    },
    %{
      slug: "data_analysis",
      name: "Data Analysis",
      description: "Data parsing, statistics, and transformation",
      category: "analytics",
      action_slugs: ["csv_parse", "json_parse", "statistics_compute", "math_calculate", "regex_match"],
      system_prompt_fragment: "You are a data analyst. Parse data formats, compute statistics, and identify patterns in datasets."
    },
    %{
      slug: "code_review",
      name: "Code Review",
      description: "Code formatting, linting, and generation",
      category: "development",
      action_slugs: ["code_format", "code_lint", "code_generate", "git_status", "git_diff"],
      system_prompt_fragment: "You are a code reviewer. Analyze code quality, suggest improvements, and ensure consistency."
    },
    %{
      slug: "content_creation",
      name: "Content Creation",
      description: "Text transformation and content generation",
      category: "creative",
      action_slugs: ["string_transform", "template_render", "markdown_render", "base64_encode"],
      system_prompt_fragment: "You are a content creator. Draft, edit, and format content across multiple formats."
    },
    %{
      slug: "customer_support",
      name: "Customer Support",
      description: "Customer communication and issue tracking",
      category: "business",
      action_slugs: ["slack_message", "smtp_send", "memory_read", "memory_write", "memory_search"],
      system_prompt_fragment: "You are a customer support agent. Help customers resolve issues, track conversations, and escalate when needed."
    }
  ]

  @skill_map Map.new(@skills, fn s -> {s.slug, s} end)

  @doc "Returns all pre-built skills."
  @spec list() :: [map()]
  def list, do: @skills

  @doc "Get a skill by slug."
  @spec get(String.t()) :: map() | nil
  def get(slug), do: Map.get(@skill_map, slug)

  @doc "List skills by category."
  @spec list_by_category(String.t()) :: [map()]
  def list_by_category(category) do
    Enum.filter(@skills, fn s -> s.category == category end)
  end

  @doc "All unique categories."
  @spec categories() :: [String.t()]
  def categories, do: @skills |> Enum.map(& &1.category) |> Enum.uniq() |> Enum.sort()

  @doc "Resolve action modules for a skill's action_slugs."
  @spec resolve_actions(map()) :: [module()]
  def resolve_actions(%{action_slugs: slugs}) do
    registry = JidoBuilderRuntime.ActionRegistry.list()
    Enum.flat_map(slugs, fn slug ->
      case Enum.find(registry, fn a -> a.slug == slug end) do
        nil -> []
        action -> [action.module]
      end
    end)
  end
end
