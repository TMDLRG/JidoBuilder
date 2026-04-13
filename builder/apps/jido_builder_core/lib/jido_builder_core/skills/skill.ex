defmodule JidoBuilderCore.Skills.Skill do
  @moduledoc """
  Ecto schema for Skills.

  A Skill is metadata — a named set of action slugs plus a system prompt
  fragment. At runtime, the skill resolves to actions + config.
  """

  use JidoBuilderCore.Schema

  schema "skills" do
    field(:name, :string)
    field(:slug, :string)
    field(:description, :string)
    field(:category, :string)
    field(:action_slugs, {:array, :string}, default: [])
    field(:system_prompt_fragment, :string)
    field(:config, :map, default: %{})

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)

    timestamps()
  end

  def changeset(skill, attrs) do
    skill
    |> cast(attrs, [:workspace_id, :name, :slug, :description, :category,
                     :action_slugs, :system_prompt_fragment, :config])
    |> validate_required([:workspace_id, :name, :slug])
    |> unique_constraint(:slug, name: :skills_workspace_id_slug_index)
  end
end
