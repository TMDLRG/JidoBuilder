defmodule JidoBuilderRuntime.DirectiveEmitter do
  @moduledoc """
  Builds runtime directives from DB-backed configuration payloads.
  """

  alias Jido.Agent.Directive
  alias JidoBuilderRuntime.Error

  @type result(t) :: {:ok, t} | {:error, Error.t()}

  @spec from_config(map()) :: result(struct())
  def from_config(%{"kind" => kind} = config), do: from_config(config, kind)
  def from_config(%{kind: kind} = config), do: from_config(config, kind)

  def from_config(_invalid) do
    {:error, Error.new(:invalid_directive_config, "directive config must include :kind", %{})}
  end

  defp from_config(config, :emit), do: emit(config)
  defp from_config(config, "emit"), do: emit(config)

  defp from_config(config, :schedule), do: schedule(config)
  defp from_config(config, "schedule"), do: schedule(config)

  defp from_config(config, :spawn_agent), do: spawn_agent(config)
  defp from_config(config, "spawn_agent"), do: spawn_agent(config)

  defp from_config(config, :stop_child), do: stop_child(config)
  defp from_config(config, "stop_child"), do: stop_child(config)

  defp from_config(config, :stop), do: {:ok, Directive.stop(Map.get(config, :reason, :normal))}
  defp from_config(config, "stop"), do: {:ok, Directive.stop(Map.get(config, :reason, :normal))}

  defp from_config(_config, other) do
    {:error,
     Error.new(:unsupported_directive, "unsupported directive kind", %{kind: inspect(other)})}
  end

  defp emit(config) do
    with {:ok, signal_type} <- fetch_string(config, :signal_type) do
      payload = get_value(config, :payload, %{})

      try do
        signal = Jido.Signal.new!(signal_type, payload)
        {:ok, Directive.emit(signal, get_value(config, :dispatch))}
      rescue
        error ->
          {:error,
           Error.new(:invalid_emit_config, "unable to build emit directive", %{
             reason: Exception.message(error)
           })}
      end
    end
  end

  defp schedule(config) do
    with {:ok, delay_ms} <- fetch_integer(config, :delay_ms),
         {:ok, message} <- fetch_any(config, :message) do
      {:ok, Directive.schedule(delay_ms, message)}
    end
  end

  defp spawn_agent(config) do
    with {:ok, module_name} <- fetch_string(config, :agent_module),
         {:ok, module} <- module_from_name(module_name),
         {:ok, tag} <- fetch_any(config, :tag) do
      options = [opts: get_value(config, :opts, %{}), meta: get_value(config, :meta, %{})]
      {:ok, Directive.spawn_agent(module, tag, options)}
    end
  end

  defp stop_child(config) do
    with {:ok, tag} <- fetch_any(config, :tag) do
      {:ok, Directive.stop_child(tag, get_value(config, :reason, :normal))}
    end
  end

  defp module_from_name(module_name) do
    module = Module.concat([module_name])

    if Code.ensure_loaded?(module) do
      {:ok, module}
    else
      {:error,
       Error.new(:unknown_module, "module is not loaded", %{
         module: module_name,
         field: :agent_module
       })}
    end
  end

  defp fetch_string(map, key) do
    case get_value(map, key) do
      v when is_binary(v) and v != "" -> {:ok, v}
      _ -> {:error, Error.new(:invalid_config, "missing string field", %{field: key})}
    end
  end

  defp fetch_integer(map, key) do
    case get_value(map, key) do
      v when is_integer(v) and v >= 0 ->
        {:ok, v}

      _ ->
        {:error, Error.new(:invalid_config, "missing non-negative integer field", %{field: key})}
    end
  end

  defp fetch_any(map, key) do
    if Map.has_key?(map, key) or Map.has_key?(map, Atom.to_string(key)) do
      {:ok, get_value(map, key)}
    else
      {:error, Error.new(:invalid_config, "missing required field", %{field: key})}
    end
  end

  defp get_value(map, key, default \\ nil) do
    Map.get(map, key, Map.get(map, Atom.to_string(key), default))
  end
end
