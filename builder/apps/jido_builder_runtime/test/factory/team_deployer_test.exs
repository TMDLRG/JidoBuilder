defmodule JidoBuilderRuntime.Factory.TeamDeployerTest do
  @moduledoc "Epic 4.6 — Bulk team deployment tests."
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.Factory.TeamDeployer

  defp help_desk_solution do
    %{
      slug: "help_desk",
      name: "Help Desk",
      template_slugs: ["customer_service", "knowledge_curator"],
      skill_slugs: ["customer_support", "research"]
    }
  end

  describe "plan/1" do
    test "creates deployment plan from solution" do
      {:ok, plan} = TeamDeployer.plan(help_desk_solution())

      assert plan.solution == "help_desk"
      assert plan.agent_count == 2
      assert plan.status == :planned
      assert Enum.all?(plan.agents, fn a -> a.status == :planned end)
    end

    test "assigns unique agent IDs" do
      {:ok, plan} = TeamDeployer.plan(help_desk_solution())

      ids = Enum.map(plan.agents, & &1.agent_id)
      assert length(ids) == length(Enum.uniq(ids))
    end

    test "rejects invalid solution" do
      assert {:error, _} = TeamDeployer.plan(%{})
    end
  end

  describe "validate/1" do
    test "validates a plan" do
      {:ok, plan} = TeamDeployer.plan(help_desk_solution())
      assert :ok = TeamDeployer.validate(plan)
    end
  end

  describe "deploy/1" do
    test "deploys a plan" do
      {:ok, plan} = TeamDeployer.plan(help_desk_solution())
      {:ok, deployed} = TeamDeployer.deploy(plan)

      assert deployed.status == :deployed
      assert Enum.all?(deployed.agents, fn a -> a.status == :deployed end)
    end
  end
end
