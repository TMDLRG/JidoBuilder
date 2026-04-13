defmodule JidoBuilderCore.Templates.TemplateGenerativeModelTest do
  @moduledoc "Epic 1.5 — Template Generative Model Ecto schema tests."
  use ExUnit.Case, async: false

  alias JidoBuilderCore.Repo
  alias JidoBuilderCore.Templates.TemplateGenerativeModel
  alias JidoBuilderCore.Agents.Workspace
  alias JidoBuilderCore.Templates.Template

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    {:ok, workspace} =
      Repo.insert(%Workspace{
        name: "Test Workspace",
        slug: "test-ai-model-#{System.unique_integer([:positive])}",
        metadata: %{}
      })

    {:ok, template} =
      Repo.insert(%Template{
        workspace_id: workspace.id,
        name: "Test AI Agent",
        slug: "test-ai-agent-#{System.unique_integer([:positive])}",
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
        name: "Forager Model",
        matrices: %{
          "a_matrix" => [[0.8, 0.2], [0.2, 0.8]],
          "b_matrix" => [[[0.9, 0.1], [0.1, 0.9]]]
        }
      }

      changeset = TemplateGenerativeModel.changeset(%TemplateGenerativeModel{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset without required fields" do
      changeset = TemplateGenerativeModel.changeset(%TemplateGenerativeModel{}, %{})
      refute changeset.valid?
    end

    test "persists with full model definition", %{template: template} do
      attrs = %{
        template_id: template.id,
        name: "Thermostat Model",
        description: "Temperature regulation model",
        matrices: %{
          "a_matrix" => [[0.8, 0.15, 0.05], [0.15, 0.7, 0.15], [0.05, 0.15, 0.8]],
          "b_matrix" => [
            [[0.3, 0.6, 0.1], [0.1, 0.5, 0.4], [0.05, 0.25, 0.7]],
            [[0.7, 0.25, 0.05], [0.4, 0.5, 0.1], [0.1, 0.6, 0.3]]
          ]
        },
        preferences: %{"c_vector" => [-1.0, 3.0, -1.0]},
        priors: %{"d_vector" => [0.33, 0.34, 0.33]},
        policies: [%{"actions" => [0, 0]}, %{"actions" => [0, 1]}],
        config: %{"surprise_threshold" => 3.0}
      }

      {:ok, model} =
        %TemplateGenerativeModel{}
        |> TemplateGenerativeModel.changeset(attrs)
        |> Repo.insert()

      assert model.id != nil
      assert model.name == "Thermostat Model"
      assert model.matrices["a_matrix"] != nil
    end

    test "loads model from database", %{template: template} do
      {:ok, model} =
        %TemplateGenerativeModel{}
        |> TemplateGenerativeModel.changeset(%{
          template_id: template.id,
          name: "Test Model",
          matrices: %{"a" => [[1.0]]}
        })
        |> Repo.insert()

      loaded = Repo.get!(TemplateGenerativeModel, model.id)
      assert loaded.name == "Test Model"
      assert loaded.matrices == %{"a" => [[1.0]]}
    end
  end
end
