defmodule JidoBuilderWeb.StateOpsLive do
  @moduledoc """
  Phase 3.6 — State Ops editor (all 5 ops).

  Provides an interactive editor for all five Jido state operations:
    set_state, replace_state, delete_keys, set_path, delete_path.

  The operator supplies a current-state JSON blob and a payload JSON blob,
  selects the op, and previews the resulting state by running the op through
  `JidoBuilderRuntime.StateOpAction.op_struct/2` applied to the current state.
  """
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.StateOpAction

  @ops ~w(set_state replace_state delete_keys set_path delete_path)

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "State Ops",
       ops: @ops,
       result: nil,
       error: nil
     )}
  end

  @impl true
  def handle_event(
        "apply_op",
        %{
          "state_op" => %{
            "op" => op,
            "state_json" => state_json,
            "payload_json" => payload_json
          }
        },
        socket
      ) do
    with {:ok, current_state} <- parse_json(state_json),
         {:ok, payload} <- parse_json(payload_json),
         {:ok, state_op_struct} <- StateOpAction.op_struct(op, payload),
         {:ok, new_state} <- apply_op_struct(state_op_struct, current_state) do
      {:noreply, assign(socket, result: new_state, error: nil)}
    else
      {:error, reason} ->
        {:noreply, assign(socket, error: inspect(reason), result: nil)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p class="text-sm text-zinc-500 mb-4">
      Compose and preview state operations against a sample agent state.
    </p>

    <.card class="max-w-xl">
      <:header>Apply State Op</:header>
      <form id="state-ops-form" phx-submit="apply_op" class="space-y-4">
        <div>
          <label class="block text-xs font-medium mb-1">Operation</label>
          <select name="state_op[op]" class="border rounded px-2 py-1 w-full text-sm font-mono">
            <option :for={op <- @ops} value={op}>{op}</option>
          </select>
        </div>

        <div>
          <label class="block text-xs font-medium mb-1">Current State (JSON)</label>
          <textarea
            name="state_op[state_json]"
            rows="4"
            placeholder="{&quot;key&quot;: &quot;value&quot;}"
            class="border rounded px-2 py-1 w-full text-sm font-mono"
          ></textarea>
        </div>

        <div>
          <label class="block text-xs font-medium mb-1">Payload (JSON)</label>
          <textarea
            name="state_op[payload_json]"
            rows="4"
            placeholder="{&quot;new_key&quot;: &quot;new_value&quot;}"
            class="border rounded px-2 py-1 w-full text-sm font-mono"
          ></textarea>
        </div>

        <.button>Apply Op</.button>
      </form>
    </.card>

    <div :if={@result} id="state-ops-result" class="mt-6 rounded bg-green-50 border border-green-200 p-4">
      <p class="text-xs font-semibold mb-1 text-green-800">result</p>
      <pre class="font-mono text-xs whitespace-pre-wrap">{Jason.encode!(@result, pretty: true)}</pre>
    </div>

    <div :if={@error} id="state-ops-error" class="mt-6 rounded bg-red-50 border border-red-200 p-4 text-sm text-red-700">
      {@error}
    </div>
    """
  end

  defp parse_json(""), do: {:ok, %{}}

  defp parse_json(json) do
    case Jason.decode(json) do
      {:ok, map} when is_map(map) -> {:ok, map}
      {:ok, other} -> {:ok, other}
      {:error, _} -> {:error, "invalid JSON: #{inspect(json)}"}
    end
  end

  # Apply the state op struct to a current state map.
  # We simulate what the agent runtime does: fold the op into the state.
  defp apply_op_struct(state_op, current_state) do
    alias Jido.Agent.StateOp

    try do
      new_state =
        case state_op do
          %StateOp.SetState{attrs: new} ->
            Map.merge(atomize_keys(current_state), atomize_keys(new))
            |> stringify_keys()

          %StateOp.ReplaceState{state: new} ->
            stringify_keys(new)

          %StateOp.DeleteKeys{keys: keys} ->
            str_keys = Enum.map(keys, &to_string/1)
            Map.drop(current_state, str_keys)

          %StateOp.SetPath{path: path, value: value} ->
            str_path = Enum.map(path, &to_string/1)
            put_in(current_state, str_path, value)

          %StateOp.DeletePath{path: path} ->
            str_path = Enum.map(path, &to_string/1)
            pop_in(current_state, str_path) |> elem(1)

          _other ->
            current_state
        end

      {:ok, new_state}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_atom(k), v} end)
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end

  defp to_atom(k) when is_atom(k), do: k
  defp to_atom(k) when is_binary(k), do: String.to_atom(k)
end
