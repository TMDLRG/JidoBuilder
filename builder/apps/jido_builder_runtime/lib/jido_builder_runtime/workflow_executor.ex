defmodule JidoBuilderRuntime.WorkflowExecutor do
  @moduledoc """
  Executes workflow DAGs step-by-step in topological order,
  passing accumulated state between steps.

  Each step's result is logged with a shared correlation_id.
  """

  alias JidoBuilderCore.{Observability, Workflows}
  alias JidoBuilderRuntime.{Context, Error}
  alias JidoBuilderRuntime.WorkflowStrategies.{Action, Condition, Emit, Transform}

  @type execution_result :: %{
          steps_completed: non_neg_integer(),
          final_state: map(),
          elapsed_ms: non_neg_integer(),
          step_results: [map()],
          correlation_id: String.t()
        }

  @spec execute(map(), pos_integer(), map()) ::
          {:ok, execution_result()} | {:error, Error.t()}
  def execute(context, workflow_id, initial_state \\ %{}) do
    with {:ok, ctx} <- Context.validate(context) do
      case Workflows.get_workflow(workflow_id) do
        nil ->
          {:error, Error.new(:not_found, "workflow not found", %{workflow_id: workflow_id})}

        workflow ->
          do_execute(ctx, workflow, initial_state)
      end
    end
  end

  defp do_execute(ctx, workflow, initial_state) do
    correlation_id = Ecto.UUID.generate()
    steps = Workflows.list_workflow_steps(workflow.id)
    edges = Workflows.list_workflow_edges(workflow.id)
    metadata = workflow.metadata || %{}
    error_policy = metadata["error_policy"] || Map.get(metadata, :error_policy, "stop_on_error")

    ordered_steps = topological_sort(steps, edges)

    opts = %{error_policy: error_policy}

    {elapsed_us, result} =
      :timer.tc(fn ->
        run_steps(ctx, ordered_steps, initial_state, correlation_id, [], opts)
      end)

    elapsed_ms = div(elapsed_us, 1_000)

    case result do
      {:ok, final_state, step_results} ->
        log_execution(ctx, workflow, correlation_id, :ok, elapsed_ms)

        {:ok,
         %{
           steps_completed: length(step_results),
           final_state: final_state,
           elapsed_ms: elapsed_ms,
           step_results: Enum.reverse(step_results),
           correlation_id: correlation_id
         }}

      {:error, error, step_results} ->
        log_execution(ctx, workflow, correlation_id, :error, elapsed_ms)

        {:error,
         Error.new(:workflow_execution_failed, "workflow step failed", %{
           error: inspect(error),
           steps_completed: length(step_results),
           correlation_id: correlation_id
         })}
    end
  end

  defp run_steps(_ctx, [], state, _correlation_id, results, _opts) do
    {:ok, state, results}
  end

  defp run_steps(ctx, [step | rest], state, correlation_id, results, opts) do
    max_retries = get_step_retries(step, opts)
    {step_us, step_result} = :timer.tc(fn -> execute_with_retries(step, state, max_retries) end)
    step_ms = div(step_us, 1_000)

    case step_result do
      {:ok, new_state} ->
        result = %{
          step_id: step.id,
          step_name: step.name,
          kind: step.kind,
          status: :success,
          elapsed_ms: step_ms,
          correlation_id: correlation_id
        }

        log_step(ctx, step, correlation_id, "ok", step_ms)
        merged_state = Map.merge(state, new_state)
        run_steps(ctx, rest, merged_state, correlation_id, [result | results], opts)

      {:error, reason} ->
        result = %{
          step_id: step.id,
          step_name: step.name,
          kind: step.kind,
          status: :error,
          error: inspect(reason),
          elapsed_ms: step_ms,
          correlation_id: correlation_id
        }

        log_step(ctx, step, correlation_id, "error", step_ms)

        case opts.error_policy do
          "skip_and_continue" ->
            # Skip the failed step, continue with rest
            run_steps(ctx, rest, state, correlation_id, [result | results], opts)

          _ ->
            # stop_on_error (default) and retry_once (retries already exhausted)
            {:error, reason, [result | results]}
        end
    end
  end

  defp execute_with_retries(step, state, 0), do: execute_step(step, state)

  defp execute_with_retries(step, state, retries) when retries > 0 do
    case execute_step(step, state) do
      {:ok, _} = success -> success
      {:error, _} -> execute_with_retries(step, state, retries - 1)
    end
  end

  defp get_step_retries(step, opts) do
    config = step.config || %{}
    step_retries = config["max_retries"] || Map.get(config, :max_retries)

    cond do
      is_integer(step_retries) -> step_retries
      opts.error_policy == "retry_once" -> 1
      true -> 0
    end
  end

  defp execute_step(%{kind: "transform"} = step, state), do: Transform.execute(step, state)
  defp execute_step(%{kind: "condition"} = step, state), do: Condition.execute(step, state)
  defp execute_step(%{kind: "action"} = step, state), do: Action.execute(step, state)
  defp execute_step(%{kind: "emit"} = step, state), do: Emit.execute(step, state)
  defp execute_step(%{kind: _kind}, _state), do: {:ok, %{}}

  @doc """
  Topological sort using Kahn's algorithm.
  Falls back to step_order when no edges exist.
  """
  def topological_sort(steps, []) do
    Enum.sort_by(steps, & &1.step_order)
  end

  def topological_sort(steps, edges) do
    step_map = Map.new(steps, &{&1.id, &1})

    # Build adjacency list and in-degree count
    adjacency =
      Enum.reduce(edges, %{}, fn edge, acc ->
        Map.update(acc, edge.source_step_id, [edge.target_step_id], &[edge.target_step_id | &1])
      end)

    in_degree =
      Enum.reduce(edges, Map.new(steps, &{&1.id, 0}), fn edge, acc ->
        Map.update(acc, edge.target_step_id, 1, &(&1 + 1))
      end)

    # Start with nodes having no incoming edges
    queue =
      in_degree
      |> Enum.filter(fn {_id, degree} -> degree == 0 end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.sort()

    kahn_sort(queue, adjacency, in_degree, step_map, [])
  end

  defp kahn_sort([], _adjacency, _in_degree, _step_map, result) do
    Enum.reverse(result)
  end

  defp kahn_sort([node_id | rest], adjacency, in_degree, step_map, result) do
    step = Map.get(step_map, node_id)
    neighbors = Map.get(adjacency, node_id, [])

    # Reduce in-degree for neighbors
    {updated_in_degree, new_queue_additions} =
      Enum.reduce(neighbors, {in_degree, []}, fn neighbor_id, {deg, additions} ->
        new_deg = Map.update!(deg, neighbor_id, &(&1 - 1))

        if new_deg[neighbor_id] == 0 do
          {new_deg, [neighbor_id | additions]}
        else
          {new_deg, additions}
        end
      end)

    new_queue = rest ++ Enum.sort(new_queue_additions)
    kahn_sort(new_queue, adjacency, updated_in_degree, step_map, [step | result])
  end

  defp log_step(ctx, step, correlation_id, status, elapsed_ms) do
    attrs =
      Context.base_log_attrs(ctx, %{
        directive_type: "workflow.step.#{step.kind}",
        status: status,
        payload: %{step_id: step.id, step_name: step.name, elapsed_ms: elapsed_ms},
        correlation_id: correlation_id
      })

    _ = Observability.log_directive(attrs, ctx.actor)
    :ok
  end

  defp log_execution(ctx, workflow, correlation_id, status, elapsed_ms) do
    attrs =
      Context.base_log_attrs(ctx, %{
        directive_type: "workflow.execution",
        status: to_string(status),
        payload: %{
          workflow_id: workflow.id,
          workflow_name: workflow.name,
          elapsed_ms: elapsed_ms
        },
        correlation_id: correlation_id
      })

    _ = Observability.log_directive(attrs, ctx.actor)
    :ok
  end

end
