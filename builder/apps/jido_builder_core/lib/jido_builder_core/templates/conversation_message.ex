defmodule JidoBuilderCore.Templates.ConversationMessage do
  @moduledoc """
  Persisted conversation message for LLM agent chat threads.

  Groups messages into conversations via `conversation_id` string.
  Stores role, content, and optional tool_data for tool_use/tool_result messages.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversation_messages" do
    field :conversation_id, :string
    field :role, :string
    field :content, :string
    field :tool_data, :map, default: %{}

    belongs_to :template, JidoBuilderCore.Templates.Template

    timestamps()
  end

  @required_fields ~w(template_id conversation_id role)a
  @optional_fields ~w(content tool_data)a

  def changeset(message, attrs) do
    message
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:role, ~w(user assistant tool_call tool_result system))
    |> foreign_key_constraint(:template_id)
  end
end
