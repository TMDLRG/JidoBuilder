defmodule JidoBuilderRuntime.StateOpAction do
  @moduledoc """
  Generic action that turns DB-backed state-op rows into `Jido.Agent.StateOp` structs.
  """

  use Jido.Action,
    name: "builder_state_op",
    description: "Apply a configured state operation",
    schema: [
      op: [type: :string, required: true],
      payload: [type: :map, default: %{}]
    ]

  alias Jido.Agent.StateOp
  alias JidoBuilderRuntime.Error

  @spec run(map(), map()) :: {:ok, map(), [struct()]} | {:error, Error.t()}
  def run(%{op: op, payload: payload}, _context) do
    case op_struct(op, payload) do
      {:ok, effect} -> {:ok, %{}, [effect]}
      {:error, _} = error -> error
    end
  end

  @spec op_struct(String.t(), map()) :: {:ok, struct()} | {:error, Error.t()}
  def op_struct(op, payload)

  def op_struct("set_state", payload), do: {:ok, StateOp.set_state(payload)}

  def op_struct("replace_state", payload), do: {:ok, StateOp.replace_state(payload)}

  def op_struct("delete_keys", %{"keys" => keys}),
    do: {:ok, StateOp.delete_keys(Enum.map(keys, &to_atom/1))}

  def op_struct("delete_keys", %{keys: keys}),
    do: {:ok, StateOp.delete_keys(Enum.map(keys, &to_atom/1))}

  def op_struct("set_path", payload), do: set_path(payload)

  def op_struct("delete_path", payload), do: delete_path(payload)

  def op_struct(other, _payload) do
    {:error, Error.new(:unsupported_state_op, "unsupported state operation", %{op: other})}
  end

  defp set_path(payload) do
    with {:ok, path} <- fetch_path(payload),
         {:ok, value} <- fetch_value(payload) do
      {:ok, StateOp.set_path(path, value)}
    end
  end

  defp delete_path(payload) do
    with {:ok, path} <- fetch_path(payload) do
      {:ok, StateOp.delete_path(path)}
    end
  end

  defp fetch_path(%{"path" => path}), do: {:ok, Enum.map(path, &to_atom/1)}
  defp fetch_path(%{path: path}), do: {:ok, Enum.map(path, &to_atom/1)}

  defp fetch_path(_),
    do: {:error, Error.new(:invalid_state_op_payload, "missing path", %{field: :path})}

  defp fetch_value(%{"value" => value}), do: {:ok, value}
  defp fetch_value(%{value: value}), do: {:ok, value}

  defp fetch_value(_),
    do: {:error, Error.new(:invalid_state_op_payload, "missing value", %{field: :value})}

  defp to_atom(v) when is_atom(v), do: v
  defp to_atom(v) when is_binary(v), do: String.to_atom(v)
end
