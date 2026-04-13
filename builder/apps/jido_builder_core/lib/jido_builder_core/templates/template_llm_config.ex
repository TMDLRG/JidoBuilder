defmodule JidoBuilderCore.Templates.TemplateLlmConfig do
  @moduledoc """
  Ecto schema for LLM configuration associated with agent templates.

  Stores provider, model, system prompt, temperature, and tool whitelist
  for LLM-backed agents.
  """

  use JidoBuilderCore.Schema

  schema "template_llm_configs" do
    field(:provider, :string)
    field(:model, :string)
    field(:system_prompt, :string)
    field(:temperature, :float, default: 0.7)
    field(:max_tokens, :integer, default: 1024)
    field(:tool_whitelist, {:array, :string}, default: [])
    field(:config, :map, default: %{})

    belongs_to(:template, JidoBuilderCore.Templates.Template)

    timestamps()
  end

  def changeset(llm_config, attrs) do
    llm_config
    |> cast(attrs, [
      :template_id,
      :provider,
      :model,
      :system_prompt,
      :temperature,
      :max_tokens,
      :tool_whitelist,
      :config
    ])
    |> validate_required([:template_id, :provider, :model])
    |> validate_inclusion(:provider, ["anthropic", "openai", "mock"])
    |> validate_number(:temperature, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 2.0)
    |> validate_number(:max_tokens, greater_than: 0)
    |> foreign_key_constraint(:template_id)
  end
end
