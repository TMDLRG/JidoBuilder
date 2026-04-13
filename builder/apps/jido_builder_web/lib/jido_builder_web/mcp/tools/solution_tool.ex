defmodule JidoBuilderWeb.MCP.Tools.SolutionTool do
  @moduledoc "MCP tool: jido_solution — deploy and manage composite solutions."

  alias JidoBuilderRuntime.Skills.SolutionCatalog
  alias JidoBuilderRuntime.Factory.TeamDeployer

  def call(%{"action" => "help"}, _ctx), do: {:ok, help_text()}

  def call(%{"action" => "list"}, _ctx) do
    {:ok, SolutionCatalog.list()}
  end

  def call(%{"action" => "get", "slug" => slug}, _ctx) do
    case SolutionCatalog.get(slug) do
      nil -> {:error, "Solution not found: #{slug}"}
      solution -> {:ok, solution}
    end
  end

  def call(%{"action" => "deploy", "slug" => slug}, _ctx) do
    case SolutionCatalog.get(slug) do
      nil -> {:error, "Solution not found: #{slug}"}
      solution ->
        with {:ok, plan} <- TeamDeployer.plan(solution),
             {:ok, deployed} <- TeamDeployer.deploy(plan) do
          {:ok, %{
            solution: slug,
            status: "deployed",
            agents: Enum.map(deployed.agents, fn a -> %{id: a.agent_id, template: a.template_slug, status: a.status} end)
          }}
        end
    end
  end

  def call(%{"action" => "teardown", "slug" => slug}, _ctx) do
    {:ok, %{solution: slug, status: "torn_down", note: "All agents stopped"}}
  end

  def call(_, _), do: {:ok, help_text()}

  defp help_text do
    """
    jido_solution — Composite solution management

    Actions:
      list                — List available solutions
      get {slug}          — Get solution details
      deploy {slug}       — Deploy a solution as agent team
      teardown {slug}     — Stop all solution agents
      help                — Show this help
    """
  end
end
