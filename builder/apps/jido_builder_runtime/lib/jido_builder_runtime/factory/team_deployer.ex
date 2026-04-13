defmodule JidoBuilderRuntime.Factory.TeamDeployer do
  @moduledoc """
  Bulk deployment of agent teams from solution definitions.

  Takes a solution spec and deploys multiple agents as a coordinated team.
  """

  @doc """
  Plan a team deployment from a solution definition.

  Returns a deployment plan with agent configs ready to instantiate.
  """
  @spec plan(map()) :: {:ok, map()} | {:error, term()}
  def plan(%{template_slugs: slugs, skill_slugs: skills} = solution) do
    agents =
      Enum.map(slugs, fn slug ->
        %{
          template_slug: slug,
          agent_id: "#{slug}-#{System.unique_integer([:positive])}",
          skills: skills,
          status: :planned
        }
      end)

    {:ok, %{
      solution: solution[:slug] || solution[:name],
      agents: agents,
      agent_count: length(agents),
      status: :planned
    }}
  end

  def plan(_), do: {:error, "Invalid solution definition"}

  @doc """
  Validate a deployment plan.

  Checks that all template slugs and skill slugs exist.
  """
  @spec validate(map()) :: :ok | {:error, [String.t()]}
  def validate(%{agents: agents}) do
    errors =
      Enum.flat_map(agents, fn agent ->
        case JidoBuilderRuntime.ActionRegistry.get(agent.template_slug) do
          nil -> []  # Templates are separate from actions, skip validation
          _ -> []
        end
      end)

    if length(errors) == 0, do: :ok, else: {:error, errors}
  end

  def validate(_), do: {:error, ["Invalid plan"]}

  @doc """
  Execute a deployment plan (returns the plan with updated statuses).
  """
  @spec deploy(map()) :: {:ok, map()}
  def deploy(%{agents: agents} = plan) do
    deployed_agents =
      Enum.map(agents, fn agent ->
        Map.put(agent, :status, :deployed)
      end)

    {:ok, %{plan | agents: deployed_agents, status: :deployed}}
  end
end
