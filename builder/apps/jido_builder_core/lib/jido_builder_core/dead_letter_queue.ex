defmodule JidoBuilderCore.DeadLetterQueue do
  @moduledoc """
  Context for Dead Letter Queue operations.

  Failed signals that cannot be delivered are enqueued here for later
  inspection, retry, or purge.
  """

  import Ecto.Query

  alias JidoBuilderCore.DeadLetterQueue.Entry
  alias JidoBuilderCore.Repo

  @doc "Enqueue a failed signal into the dead letter queue."
  @spec enqueue(map()) :: {:ok, Entry.t()} | {:error, Ecto.Changeset.t()}
  def enqueue(attrs) do
    %Entry{}
    |> Entry.changeset(attrs)
    |> Repo.insert()
  end

  @doc "List DLQ entries for a workspace, most recent first."
  @spec list(integer(), keyword()) :: [Entry.t()]
  def list(workspace_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    Entry
    |> where([e], e.workspace_id == ^workspace_id)
    |> order_by([e], [desc: e.inserted_at])
    |> limit(^limit)
    |> Repo.all()
  end

  @doc "Mark a DLQ entry as retried."
  @spec retry(integer()) :: {:ok, Entry.t()} | {:error, Ecto.Changeset.t()}
  def retry(entry_id) do
    entry = Repo.get!(Entry, entry_id)

    entry
    |> Entry.changeset(%{status: "retried"})
    |> Repo.update()
  end

  @doc "Mark a DLQ entry as purged."
  @spec purge(integer()) :: {:ok, Entry.t()} | {:error, Ecto.Changeset.t()}
  def purge(entry_id) do
    entry = Repo.get!(Entry, entry_id)

    entry
    |> Entry.changeset(%{status: "purged"})
    |> Repo.update()
  end

  @doc "Count pending entries for a workspace."
  @spec count_pending(integer()) :: non_neg_integer()
  def count_pending(workspace_id) do
    Entry
    |> where([e], e.workspace_id == ^workspace_id and e.status == "pending")
    |> Repo.aggregate(:count)
  end
end
