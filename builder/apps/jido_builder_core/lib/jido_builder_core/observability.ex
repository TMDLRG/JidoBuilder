defmodule JidoBuilderCore.Observability do
  import Ecto.Query

  alias JidoBuilderCore.Audit
  alias JidoBuilderCore.Observability.{DirectiveLog, SignalLog}
  alias JidoBuilderCore.Repo

  @doc """
  Translates a raw Jido telemetry event map (as produced by
  `JidoBuilderRuntime.TelemetryBridge.normalize/3`) into a
  human-readable row suitable for stream display.

  Returns a map with:
    - `:label`      — plain-English description of what happened
    - `:status`     — `:success | :error | :running | :unknown`
    - `:agent_link` — path to the agent detail page, or `nil`
    - `:ts`         — the measured-at timestamp (passes through)
    - `:next_hint`  — guidance string shown on `:error` rows, else `nil`
  """
  def translate_event(%{} = event) do
    status = derive_status(event)
    agent_id = Map.get(event, :agent_id)
    kind = Map.get(event, :kind, "")
    metadata = Map.get(event, :metadata, %{})
    duration_ms = format_duration(Map.get(event, :duration_native))
    action = Map.get(metadata, :action) || Map.get(metadata, "action")

    label =
      build_label(kind, status, agent_id, action, duration_ms)

    next_hint =
      if status == :error do
        "Open the worker's debug panel to inspect the error."
      else
        nil
      end

    %{
      label: label,
      status: status,
      agent_link: agent_link(agent_id),
      ts: Map.get(event, :measured_at),
      next_hint: next_hint
    }
  end

  defp derive_status(%{status: s}) do
    case to_string(s) do
      s when s in ["stop", "ok", "success"] -> :success
      "start" -> :running
      s when s in ["exception", "error"] -> :error
      _ -> :unknown
    end
  end

  defp build_label("cmd", :success, agent_id, action, duration_ms) do
    base = "Worker #{agent_id || "unknown"}"
    task = if action, do: " completed task #{action}", else: " completed a task"
    time = if duration_ms, do: " in #{duration_ms}", else: ""
    base <> task <> time
  end

  defp build_label("cmd", :error, agent_id, action, _duration_ms) do
    base = "Worker #{agent_id || "unknown"}"
    task = if action, do: " failed on task #{action}", else: " encountered an error"
    base <> task
  end

  defp build_label("cmd", :running, agent_id, action, _duration_ms) do
    task = if action, do: " running #{action}", else: " started a task"
    "Worker #{agent_id || "unknown"}" <> task
  end

  defp build_label("signal", status, agent_id, _action, _duration_ms) do
    "Signal #{status} for #{agent_id || "unknown"}"
  end

  defp build_label("directive", status, agent_id, _action, _duration_ms) do
    "Directive #{status} on #{agent_id || "unknown"}"
  end

  defp build_label("action", :success, agent_id, action, duration_ms) do
    base = "Action #{action || "unknown"} on #{agent_id || "unknown"}"
    time = if duration_ms, do: " in #{duration_ms}", else: ""
    base <> time
  end

  defp build_label(_kind, status, agent_id, _action, _duration_ms) do
    "Event #{status} — agent #{agent_id || "unknown"}"
  end

  defp format_duration(nil), do: nil
  defp format_duration(native) when is_integer(native) do
    ms = System.convert_time_unit(native, :native, :millisecond)
    "#{ms}ms"
  end

  defp agent_link(nil), do: nil
  defp agent_link(agent_id), do: "/agents/#{agent_id}"

  def log_signal(attrs, actor),
    do: insert_with_audit(SignalLog, attrs, actor, "observability.signals.create")

  def log_directive(attrs, actor),
    do: insert_with_audit(DirectiveLog, attrs, actor, "observability.directives.create")

  def log_error(attrs, actor) do
    attrs
    |> Map.put_new(:directive_type, "runtime.error")
    |> Map.put_new(:status, "error")
    |> log_directive(actor)
  end

  def log_trace(attrs, actor) do
    attrs
    |> Map.put_new(:directive_type, "runtime.trace")
    |> Map.put_new(:status, "ok")
    |> log_directive(actor)
  end

  @doc """
  Returns all signal_logs and directive_logs matching a given correlation_id
  within a workspace. Used to trace the full execution lifecycle of a dispatch.
  """
  @spec get_by_correlation_id(pos_integer(), String.t()) :: %{
          signal_logs: [SignalLog.t()],
          directive_logs: [DirectiveLog.t()]
        }
  def get_by_correlation_id(workspace_id, correlation_id) do
    signal_logs =
      from(log in SignalLog,
        where: log.workspace_id == ^workspace_id and log.correlation_id == ^correlation_id,
        order_by: [asc: log.inserted_at]
      )
      |> Repo.all()

    directive_logs =
      from(log in DirectiveLog,
        where: log.workspace_id == ^workspace_id and log.correlation_id == ^correlation_id,
        order_by: [asc: log.inserted_at]
      )
      |> Repo.all()

    %{signal_logs: signal_logs, directive_logs: directive_logs}
  end

  @doc "Returns signal_logs for a specific agent instance."
  def list_agent_signals(agent_instance_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    from(log in SignalLog,
      where: log.agent_instance_id == ^agent_instance_id,
      order_by: [desc: log.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc "Counts signal_logs for a specific agent instance."
  def count_agent_signals(agent_instance_id) do
    from(log in SignalLog, where: log.agent_instance_id == ^agent_instance_id)
    |> Repo.aggregate(:count)
  end

  @doc "Counts error directive_logs for a specific agent."
  def count_agent_errors(workspace_id, agent_name) do
    from(log in DirectiveLog,
      where:
        log.workspace_id == ^workspace_id and
          log.directive_type == "runtime.error" and
          fragment("json_extract(payload, '$.agent_id') = ?", ^agent_name)
    )
    |> Repo.aggregate(:count)
  end

  def list_recent_signals(workspace_id, opts \\ []) do
    workspace_id
    |> signal_query()
    |> maybe_limit(opts)
    |> Repo.all()
  end

  def list_recent_directives(workspace_id, opts \\ []) do
    workspace_id
    |> directive_query()
    |> maybe_limit(opts)
    |> Repo.all()
  end

  def list_recent_errors(workspace_id, opts \\ []) do
    workspace_id
    |> directive_query()
    |> where([log], log.directive_type == "runtime.error")
    |> maybe_limit(opts)
    |> Repo.all()
  end

  def list_recent_traces(workspace_id, opts \\ []) do
    workspace_id
    |> directive_query()
    |> where([log], log.directive_type == "runtime.trace")
    |> maybe_limit(opts)
    |> Repo.all()
  end

  defp signal_query(workspace_id) do
    from(log in SignalLog,
      where: log.workspace_id == ^workspace_id,
      order_by: [desc: log.inserted_at]
    )
  end

  defp directive_query(workspace_id) do
    from(log in DirectiveLog,
      where: log.workspace_id == ^workspace_id,
      order_by: [desc: log.inserted_at]
    )
  end

  defp maybe_limit(query, opts) do
    limit = Keyword.get(opts, :limit, 100)
    from(record in query, limit: ^limit)
  end

  defp insert_with_audit(schema, attrs, actor, action) do
    struct(schema)
    |> schema.changeset(attrs)
    |> Repo.insert()
    |> maybe_audit(actor, action)
  end

  defp maybe_audit({:ok, record} = ok, actor, action) do
    _ = Audit.log(actor, action, record, %{})
    ok
  end

  defp maybe_audit(error, _actor, _action), do: error
end
