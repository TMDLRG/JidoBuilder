defmodule JidoBuilderCore.Templates.TemplateGenerativeModel do
  @moduledoc """
  Ecto schema for storing Active Inference generative model configurations
  associated with agent templates.

  Stores POMDP matrices (A, B, C, D) and policy space as JSON,
  enabling persistence of Active Inference model definitions.
  """

  use JidoBuilderCore.Schema

  schema "template_generative_models" do
    field(:name, :string)
    field(:description, :string)
    field(:matrices, :map, default: %{})
    field(:preferences, :map, default: %{})
    field(:priors, :map, default: %{})
    field(:policies, {:array, :map}, default: [])
    field(:config, :map, default: %{})

    belongs_to(:template, JidoBuilderCore.Templates.Template)

    timestamps()
  end

  def changeset(model, attrs) do
    model
    |> cast(attrs, [
      :template_id,
      :name,
      :description,
      :matrices,
      :preferences,
      :priors,
      :policies,
      :config
    ])
    |> validate_required([:template_id, :name, :matrices])
    |> foreign_key_constraint(:template_id)
  end
end
