defmodule JidoBuilderRuntime.CircuitBreaker do
  @moduledoc """
  ETS-backed circuit breaker per {workspace_id, agent_name}.

  States:
    - :closed  — normal operation, calls allowed
    - :open    — rejecting calls after N consecutive failures
    - :half_open — timeout elapsed, single probe allowed

  Opens after `threshold` consecutive failures (default 5).
  After `timeout_ms` (default 30_000) in :open, transitions to :half_open.
  A successful probe in :half_open closes the breaker; a failed probe re-opens it.
  """

  use GenServer

  @table :jido_circuit_breakers
  @default_threshold 5
  @default_timeout_ms 30_000

  # ── Public API ──────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Returns the current state of the breaker for `key`."
  @spec state(term()) :: :closed | :open | :half_open
  def state(key) do
    case lookup(key) do
      nil ->
        :closed

      {_failures, :open, opened_at, timeout_ms} ->
        if System.monotonic_time(:millisecond) - opened_at >= timeout_ms do
          :half_open
        else
          :open
        end

      {_failures, breaker_state, _opened_at, _timeout_ms} ->
        breaker_state
    end
  end

  @doc "Returns true if the breaker allows a call through."
  @spec allow?(term()) :: boolean()
  def allow?(key) do
    case state(key) do
      :closed -> true
      :half_open -> true
      :open -> false
    end
  end

  @doc "Records a successful call. Resets failure count and closes the breaker."
  @spec record_success(term()) :: :ok
  def record_success(key) do
    ensure_table()
    :ets.insert(@table, {key, 0, :closed, 0, @default_timeout_ms})
    :ok
  end

  @doc "Records a failed call. Opens breaker after threshold failures."
  @spec record_failure(term(), keyword()) :: :ok
  def record_failure(key, opts \\ []) do
    ensure_table()
    threshold = Keyword.get(opts, :threshold, @default_threshold)
    timeout_ms = Keyword.get(opts, :timeout_ms, @default_timeout_ms)

    current_state = state(key)
    current = lookup(key)
    failures = if current, do: elem(current, 0), else: 0

    new_failures = failures + 1

    cond do
      # Failed probe in half_open → reopen
      current_state == :half_open ->
        :ets.insert(@table, {key, new_failures, :open, System.monotonic_time(:millisecond), timeout_ms})

      # Reached threshold → open
      new_failures >= threshold ->
        :ets.insert(@table, {key, new_failures, :open, System.monotonic_time(:millisecond), timeout_ms})

      # Still under threshold → stay closed
      true ->
        :ets.insert(@table, {key, new_failures, :closed, 0, timeout_ms})
    end

    :ok
  end

  @doc "Resets the breaker for `key` back to closed with zero failures."
  @spec reset(term()) :: :ok
  def reset(key) do
    ensure_table()
    :ets.delete(@table, key)
    :ok
  end

  @doc "Returns a list of all breaker entries (for dashboard display)."
  @spec list_all() :: list()
  def list_all do
    ensure_table()

    :ets.tab2list(@table)
    |> Enum.map(fn {key, failures, raw_state, opened_at, timeout_ms} ->
      resolved_state =
        if raw_state == :open and System.monotonic_time(:millisecond) - opened_at >= timeout_ms do
          :half_open
        else
          raw_state
        end

      %{key: key, failures: failures, state: resolved_state}
    end)
  end

  # ── GenServer callbacks ─────────────────────────────────────

  @impl true
  def init(_opts) do
    table = :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    {:ok, %{table: table}}
  end

  # ── Private ─────────────────────────────────────────────────

  defp lookup(key) do
    ensure_table()

    case :ets.lookup(@table, key) do
      [{^key, failures, breaker_state, opened_at, timeout_ms}] ->
        {failures, breaker_state, opened_at, timeout_ms}

      [] ->
        nil
    end
  end

  defp ensure_table do
    case :ets.info(@table) do
      :undefined ->
        :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])

      _ ->
        :ok
    end
  end
end
