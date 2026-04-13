defmodule JidoBuilderWeb.MCP.Tools.LibraryTool do
  @moduledoc "MCP tool: jido_library — browse templates, workflows, solutions."

  alias JidoBuilderRuntime.ActionRegistry
  alias JidoBuilderRuntime.Skills.{SkillRegistry, SolutionCatalog}

  def call(%{"action" => "help"}, _ctx), do: {:ok, help_text()}

  def call(%{"action" => "browse_actions"} = args, _ctx) do
    actions = case args["category"] do
      nil -> ActionRegistry.list()
      cat -> ActionRegistry.list_by_category(String.to_existing_atom(cat))
    end
    {:ok, %{actions: Enum.map(actions, fn a -> %{slug: a.slug, name: a.name, description: a.description, category: a.category} end), count: length(actions)}}
  rescue
    _ -> {:ok, %{actions: ActionRegistry.list() |> Enum.map(fn a -> %{slug: a.slug, name: a.name, category: a.category} end), count: length(ActionRegistry.list())}}
  end

  def call(%{"action" => "browse_skills"}, _ctx) do
    {:ok, SkillRegistry.list()}
  end

  def call(%{"action" => "browse_solutions"}, _ctx) do
    {:ok, SolutionCatalog.list()}
  end

  def call(%{"action" => "categories"}, _ctx) do
    {:ok, %{
      action_categories: ActionRegistry.categories(),
      skill_categories: SkillRegistry.categories()
    }}
  end

  def call(%{"action" => "search", "query" => query}, _ctx) do
    q = String.downcase(query)
    actions = ActionRegistry.list()
      |> Enum.filter(fn a -> String.contains?(String.downcase(a.name), q) or String.contains?(String.downcase(a.description), q) end)
      |> Enum.map(fn a -> %{slug: a.slug, name: a.name, type: "action"} end)

    skills = SkillRegistry.list()
      |> Enum.filter(fn s -> String.contains?(String.downcase(s.name), q) or String.contains?(String.downcase(s.description), q) end)
      |> Enum.map(fn s -> %{slug: s.slug, name: s.name, type: "skill"} end)

    {:ok, %{results: actions ++ skills, count: length(actions) + length(skills)}}
  end

  def call(_, _), do: {:ok, help_text()}

  defp help_text do
    """
    jido_library — Browse the template library

    Actions:
      browse_actions {category}  — List available actions (optionally by category)
      browse_skills              — List available skills
      browse_solutions           — List available solutions
      categories                 — List all categories
      search {query}             — Search actions and skills
      help                       — Show this help
    """
  end
end
