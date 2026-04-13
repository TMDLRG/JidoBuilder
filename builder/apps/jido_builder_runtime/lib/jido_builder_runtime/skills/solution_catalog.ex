defmodule JidoBuilderRuntime.Skills.SolutionCatalog do
  @moduledoc """
  Catalog of pre-built composite business solutions.

  Each solution composes multiple agent templates + workflow definitions
  into a deployable business package.
  """

  @solutions [
    %{
      slug: "help_desk",
      name: "Help Desk",
      description: "Triage agent + resolver agent + escalation workflow",
      category: "support",
      template_slugs: ["customer_service", "knowledge_curator"],
      workflow_slugs: ["customer_onboarding", "incident_response"],
      skill_slugs: ["customer_support", "research"]
    },
    %{
      slug: "content_pipeline",
      name: "Content Pipeline",
      description: "Research → writer → editor → publisher workflow",
      category: "creative",
      template_slugs: ["research", "content_writer"],
      workflow_slugs: ["content_pipeline"],
      skill_slugs: ["research", "content_creation"]
    },
    %{
      slug: "devops_suite",
      name: "DevOps Suite",
      description: "Monitor + alerting + diagnostics + remediation",
      category: "engineering",
      template_slugs: ["devops", "qa"],
      workflow_slugs: ["incident_response", "code_review_pipeline"],
      skill_slugs: ["code_review"]
    },
    %{
      slug: "sales_pipeline",
      name: "Sales Pipeline",
      description: "SDR + qualifier + proposal generator + CRM workflow",
      category: "sales",
      template_slugs: ["sales", "personal_assistant"],
      workflow_slugs: ["lead_qualification", "approval_workflow"],
      skill_slugs: ["customer_support", "data_analysis"]
    },
    %{
      slug: "knowledge_base",
      name: "Knowledge Base",
      description: "Ingestion + indexer + retrieval + QA workflow",
      category: "knowledge",
      template_slugs: ["knowledge_curator", "data_analyst"],
      workflow_slugs: ["knowledge_ingestion", "report_generation"],
      skill_slugs: ["research", "data_analysis"]
    }
  ]

  @solution_map Map.new(@solutions, fn s -> {s.slug, s} end)

  @doc "Returns all available solutions."
  @spec list() :: [map()]
  def list, do: @solutions

  @doc "Get a solution by slug."
  @spec get(String.t()) :: map() | nil
  def get(slug), do: Map.get(@solution_map, slug)

  @doc "List solutions by category."
  @spec list_by_category(String.t()) :: [map()]
  def list_by_category(category) do
    Enum.filter(@solutions, fn s -> s.category == category end)
  end
end
