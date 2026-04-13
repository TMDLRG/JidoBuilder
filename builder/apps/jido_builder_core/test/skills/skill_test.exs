defmodule JidoBuilderCore.Skills.SkillTest do
  @moduledoc "Epic 3.5 — Skill Ecto schema tests."
  use ExUnit.Case, async: false

  alias JidoBuilderCore.Repo
  alias JidoBuilderCore.Skills.Skill
  alias JidoBuilderCore.Agents.Workspace

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    {:ok, workspace} =
      Repo.insert(%Workspace{
        name: "Skills Workspace",
        slug: "skills-ws-#{System.unique_integer([:positive])}",
        metadata: %{}
      })

    %{workspace: workspace}
  end

  describe "changeset/2" do
    test "valid changeset", %{workspace: ws} do
      changeset = Skill.changeset(%Skill{}, %{
        workspace_id: ws.id,
        name: "Research",
        slug: "research"
      })
      assert changeset.valid?
    end

    test "invalid without name" do
      changeset = Skill.changeset(%Skill{}, %{slug: "test"})
      refute changeset.valid?
    end

    test "persists with full fields", %{workspace: ws} do
      {:ok, skill} =
        %Skill{}
        |> Skill.changeset(%{
          workspace_id: ws.id,
          name: "Data Analysis",
          slug: "data-analysis-#{System.unique_integer([:positive])}",
          description: "Analyze data",
          category: "analytics",
          action_slugs: ["csv_parse", "statistics_compute"],
          system_prompt_fragment: "You are a data analyst.",
          config: %{max_results: 100}
        })
        |> Repo.insert()

      assert skill.id != nil
      assert skill.name == "Data Analysis"
      assert "csv_parse" in skill.action_slugs
    end

    test "loads from database", %{workspace: ws} do
      {:ok, skill} =
        %Skill{}
        |> Skill.changeset(%{
          workspace_id: ws.id,
          name: "Test Skill",
          slug: "test-skill-#{System.unique_integer([:positive])}"
        })
        |> Repo.insert()

      loaded = Repo.get!(Skill, skill.id)
      assert loaded.name == "Test Skill"
    end
  end
end
