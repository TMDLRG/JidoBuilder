defmodule JidoBuilderWeb.MCP.SseSessionStore do
  @moduledoc """
  ETS-backed store for MCP SSE sessions.
  Tracks session_id -> workspace_id mapping.
  """
  use GenServer

  @table :mcp_sse_sessions

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def register(session_id, workspace_id) do
    :ets.insert(@table, {session_id, %{workspace_id: workspace_id, created_at: System.monotonic_time()}})
    :ok
  end

  def get(session_id) do
    case :ets.lookup(@table, session_id) do
      [{^session_id, data}] -> data
      [] -> nil
    end
  end

  def delete(session_id) do
    :ets.delete(@table, session_id)
    :ok
  end

  @impl true
  def init(_) do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{}}
  end
end
