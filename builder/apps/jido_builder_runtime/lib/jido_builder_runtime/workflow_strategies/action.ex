defmodule JidoBuilderRuntime.WorkflowStrategies.Action do
  @moduledoc """
  Resolves and executes an action module against workflow state.

  When `target_agent` is set in step config, dispatches the action
  as a signal to the named running agent instead of executing locally.
  """

  alias JidoBuilderRuntime.{Hiring, Signals}

  @spec execute(map(), map()) :: {:ok, map()} | {:error, term()}
  def execute(step, state) do
    config = step.config || %{}
    target_agent = config["target_agent"] || Map.get(config, :target_agent)

    if target_agent do
      dispatch_to_agent(target_agent, step, state)
    else
      execute_local(step, state)
    end
  rescue
    error ->
      {:error, %{reason: :action_execution_failed, message: Exception.message(error)}}
  end

  defp execute_local(step, state) do
    config = step.config || %{}
    module_name = config["action_module"] || Map.get(config, :action_module)
    params = config["params"] || Map.get(config, :params, %{})

    with {:ok, module} <- resolve_module(module_name),
         {:ok, result} <- module.run(params, %{state: state}) do
      {:ok, result}
    end
  end

  defp dispatch_to_agent(target_agent, step, state) do
    context = %{workspace_id: 1, actor: "workflow"}
    signal_type = step.name || "workflow.action"
    payload = Map.merge(state, %{"step" => step.name, "kind" => step.kind})

    with {:ok, server} <- Hiring.whereis(context, target_agent),
         {:ok, signal} <- Signals.new(context, signal_type, payload),
         {:ok, agent_state, _elapsed} <- Signals.timed_call(context, server, signal) do
      {:ok, %{dispatched_to: target_agent, agent_state: agent_state}}
    else
      {:error, reason} ->
        {:error, %{reason: :agent_dispatch_failed, target: target_agent, detail: inspect(reason)}}
    end
  end

  defp resolve_module(nil), do: {:error, %{reason: :no_action_module}}

  defp resolve_module(name) when is_binary(name) do
    try do
      module = String.to_existing_atom(name)

      if Code.ensure_loaded?(module) and function_exported?(module, :run, 2) do
        {:ok, module}
      else
        {:error, %{reason: :invalid_action_module, module: name}}
      end
    rescue
      ArgumentError ->
        {:error, %{reason: :module_not_found, module: name}}
    end
  end

  defp resolve_module(_), do: {:error, %{reason: :invalid_module_name}}
end
