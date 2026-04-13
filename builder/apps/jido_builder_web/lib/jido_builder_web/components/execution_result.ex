defmodule JidoBuilderWeb.Components.ExecutionResult do
  @moduledoc """
  Rich execution result panel for signal dispatch.

  Displays:
  - Status badge (success/error/timeout/pending)
  - Elapsed time in ms
  - Agent state (expandable JSON view)
  - Signal type, target agent, correlation_id
  - Error details with stack trace on failure
  """

  use Phoenix.Component

  attr :result, :map, required: true
  attr :class, :string, default: ""

  def execution_result(assigns) do
    ~H"""
    <div class={@class}>
      {render_by_status(assigns)}
    </div>
    """
  end

  defp render_by_status(%{result: %{status: :success}} = assigns) do
    ~H"""
    <div class="rounded bg-green-50 border border-green-200 p-3 text-sm space-y-2">
      <div class="flex items-center gap-2">
        <span class="inline-block w-2 h-2 rounded-full bg-green-500"></span>
        <span class="font-semibold text-green-800">Success</span>
        <span class="ml-auto text-xs text-zinc-500">{@result.elapsed_ms} ms</span>
      </div>
      <div class="grid grid-cols-2 gap-1 text-xs text-zinc-600">
        <div><span class="font-medium">Signal:</span> {@result.signal_type}</div>
        <div :if={@result[:target_agent]}><span class="font-medium">Agent:</span> {@result.target_agent}</div>
      </div>
      <div :if={@result[:correlation_id]} class="text-xs text-zinc-500">
        <span class="font-medium">Correlation:</span>
        <code class="bg-zinc-100 px-1 rounded">{@result.correlation_id}</code>
      </div>
      <details class="mt-1">
        <summary class="text-xs font-medium text-zinc-600 cursor-pointer">Agent State</summary>
        <pre class="font-mono text-xs whitespace-pre-wrap mt-1 bg-white p-2 rounded border max-h-64 overflow-auto">{format_state(@result.agent_state)}</pre>
      </details>
    </div>
    """
  end

  defp render_by_status(%{result: %{status: :error}} = assigns) do
    ~H"""
    <div class="rounded bg-red-50 border border-red-200 p-3 text-sm space-y-2">
      <div class="flex items-center gap-2">
        <span class="inline-block w-2 h-2 rounded-full bg-red-500"></span>
        <span class="font-semibold text-red-800">Error</span>
        <span class="ml-auto text-xs text-zinc-500">{@result.elapsed_ms} ms</span>
      </div>
      <div class="grid grid-cols-2 gap-1 text-xs text-zinc-600">
        <div><span class="font-medium">Signal:</span> {@result.signal_type}</div>
        <div :if={@result[:target_agent]}><span class="font-medium">Agent:</span> {@result.target_agent}</div>
      </div>
      <div :if={@result[:correlation_id]} class="text-xs text-zinc-500">
        <span class="font-medium">Correlation:</span>
        <code class="bg-zinc-100 px-1 rounded">{@result.correlation_id}</code>
      </div>
      <details open class="mt-1">
        <summary class="text-xs font-medium text-red-700 cursor-pointer">Error Details</summary>
        <pre class="font-mono text-xs whitespace-pre-wrap mt-1 bg-white p-2 rounded border text-red-700 max-h-64 overflow-auto">{@result.error}</pre>
      </details>
    </div>
    """
  end

  defp render_by_status(%{result: %{status: :pending}} = assigns) do
    ~H"""
    <div class="rounded bg-blue-50 border border-blue-200 p-3 text-sm space-y-2">
      <div class="flex items-center gap-2">
        <span class="inline-block w-2 h-2 rounded-full bg-blue-500 animate-pulse"></span>
        <span class="font-semibold text-blue-800">Dispatched (async)</span>
      </div>
      <div class="text-xs text-zinc-600">
        <span class="font-medium">Signal:</span> {@result.signal_type}
      </div>
      <div :if={@result[:target_agent]} class="text-xs text-zinc-600">
        <span class="font-medium">Agent:</span> {@result.target_agent}
      </div>
      <div :if={@result[:correlation_id]} class="text-xs text-zinc-500">
        <span class="font-medium">Correlation:</span>
        <code class="bg-zinc-100 px-1 rounded">{@result.correlation_id}</code>
      </div>
    </div>
    """
  end

  defp render_by_status(assigns) do
    ~H"""
    <div class="text-xs text-zinc-400 italic">Unknown result status</div>
    """
  end

  defp format_state(state) when is_struct(state) do
    state |> Map.from_struct() |> inspect(pretty: true, limit: :infinity)
  end

  defp format_state(state) when is_map(state) do
    inspect(state, pretty: true, limit: :infinity)
  end

  defp format_state(state), do: inspect(state)
end
