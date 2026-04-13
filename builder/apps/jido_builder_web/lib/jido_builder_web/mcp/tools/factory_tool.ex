defmodule JidoBuilderWeb.MCP.Tools.FactoryTool do
  @moduledoc "MCP tool: jido_factory — compose, clone, version, deploy teams."

  alias JidoBuilderRuntime.Factory.{Composer, Versioning, TeamDeployer}
  alias JidoBuilderRuntime.Skills.SolutionCatalog

  def call(%{"action" => "help"}, _ctx), do: {:ok, help_text()}

  def call(%{"action" => "compose", "templates" => templates}, _ctx) when is_list(templates) do
    case Composer.compose(templates, force: true) do
      {:ok, composed} -> {:ok, composed}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  def call(%{"action" => "clone", "config" => config} = args, _ctx) when is_map(config) do
    overrides = args["overrides"] || %{}
    {:ok, Versioning.clone(config, overrides)}
  end

  def call(%{"action" => "version", "config" => config} = args, _ctx) when is_map(config) do
    changelog = args["changelog"] || ""
    {:ok, Versioning.create_version(config, changelog)}
  end

  def call(%{"action" => "diff", "old" => old, "new" => new}, _ctx) do
    {:ok, Versioning.diff(old, new)}
  end

  def call(%{"action" => "deploy_team", "solution" => slug}, _ctx) when is_binary(slug) do
    case SolutionCatalog.get(slug) do
      nil -> {:error, "Solution not found: #{slug}"}
      solution ->
        with {:ok, plan} <- TeamDeployer.plan(solution),
             {:ok, deployed} <- TeamDeployer.deploy(plan) do
          {:ok, deployed}
        end
    end
  end

  def call(_, _), do: {:ok, help_text()}

  defp help_text do
    """
    jido_factory — Agent Factory operations

    Actions:
      compose {templates}     — Compose multiple template definitions
      clone {config, overrides} — Clone a config with overrides
      version {config, changelog} — Create a version snapshot
      diff {old, new}         — Compare two configs
      deploy_team {solution}  — Deploy a solution as agent team
      help                    — Show this help
    """
  end
end
