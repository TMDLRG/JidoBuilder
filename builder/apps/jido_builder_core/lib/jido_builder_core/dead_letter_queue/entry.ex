defmodule JidoBuilderCore.DeadLetterQueue.Entry do
  @moduledoc "Schema for dead letter queue entries."
  use JidoBuilderCore.Schema

  schema "dead_letter_queue" do
    field(:agent_name, :string)
    field(:signal_type, :string)
    field(:payload, :map, default: %{})
    field(:error, :string)
    field(:status, :string, default: "pending")

    belongs_to(:workspace, JidoBuilderCore.Agents.Workspace)

    timestamps()
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:workspace_id, :agent_name, :signal_type, :payload, :error, :status])
    |> validate_required([:workspace_id, :agent_name, :signal_type])
    |> validate_inclusion(:status, ~w(pending retried purged))
  end
end
