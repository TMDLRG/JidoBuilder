defmodule JidoBuilderCore.Templates.TemplateLlmConfigTest do
  @moduledoc "Epic 2.6 — Template LLM Config Ecto schema tests."
  use ExUnit.Case, async: false

  alias JidoBuilderCore.Repo
  alias JidoBuilderCore.Templates.TemplateLlmConfig
  alias JidoBuilderCore.Agents.Workspace
  alias JidoBuilderCore.Templates.Template

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    {:ok, workspace} =
      Repo.insert(%Workspace{
        name: "Test Workspace",
        slug: "test-llm-#{System.unique_integer([:positive])}",
        metadata: %{}
      })

    {:ok, template} =
      Repo.insert(%Template{
        workspace_id: workspace.id,
        name: "LLM Agent",
        slug: "llm-agent-#{System.unique_integer([:positive])}",
        version: "1.0.0",
        status: "draft",
        config: %{}
      })

    %{workspace: workspace, template: template}
  end

  describe "changeset/2" do
    test "valid changeset with required fields", %{template: template} do
      attrs = %{
        template_id: template.id,
        provider: "anthropic",
        model: "claude-sonnet-4-20250514"
      }

      changeset = TemplateLlmConfig.changeset(%TemplateLlmConfig{}, attrs)
      assert changeset.valid?
    end

    test "invalid without provider" do
      changeset = TemplateLlmConfig.changeset(%TemplateLlmConfig{}, %{model: "gpt-4"})
      refute changeset.valid?
    end

    test "validates provider inclusion" do
      changeset = TemplateLlmConfig.changeset(%TemplateLlmConfig{}, %{
        template_id: 1,
        provider: "invalid_provider",
        model: "test"
      })
      refute changeset.valid?
    end

    test "validates temperature range" do
      changeset = TemplateLlmConfig.changeset(%TemplateLlmConfig{}, %{
        template_id: 1,
        provider: "anthropic",
        model: "test",
        temperature: 3.0
      })
      refute changeset.valid?
    end

    test "persists with full config", %{template: template} do
      attrs = %{
        template_id: template.id,
        provider: "anthropic",
        model: "claude-sonnet-4-20250514",
        system_prompt: "You are a helpful assistant.",
        temperature: 0.7,
        max_tokens: 2048,
        tool_whitelist: ["echo", "search"],
        config: %{"top_p" => 0.9}
      }

      {:ok, config} =
        %TemplateLlmConfig{}
        |> TemplateLlmConfig.changeset(attrs)
        |> Repo.insert()

      assert config.id != nil
      assert config.provider == "anthropic"
      assert config.system_prompt == "You are a helpful assistant."
    end

    test "loads config from database", %{template: template} do
      {:ok, config} =
        %TemplateLlmConfig{}
        |> TemplateLlmConfig.changeset(%{
          template_id: template.id,
          provider: "mock",
          model: "mock-v1",
          temperature: 0.5
        })
        |> Repo.insert()

      loaded = Repo.get!(TemplateLlmConfig, config.id)
      assert loaded.provider == "mock"
      assert loaded.temperature == 0.5
    end
  end
end
