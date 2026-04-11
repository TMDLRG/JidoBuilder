defmodule JidoBuilderRuntime.PodRuntime do
  @moduledoc """
  Runtime facade for dynamic pod + sensor hosting from DB configuration rows.
  """

  alias JidoBuilderRuntime.{DynamicAgent, DynamicPod, Error, SensorHost}

  @type runtime :: %{agent: DynamicAgent.t(), pod: map(), sensor_host: pid() | nil}

  @spec boot(pos_integer(), keyword()) :: {:ok, runtime()} | {:error, Error.t()}
  def boot(template_id, opts \\ []) when is_integer(template_id) do
    with {:ok, agent} <-
           DynamicAgent.from_template(template_id, Map.new(opts[:agent_attrs] || %{})),
         {:ok, pod_cfg} <- DynamicPod.config_for_template(template_id),
         {:ok, sensor_pid} <- maybe_start_sensor_host(template_id, opts) do
      {:ok, %{agent: agent, pod: pod_cfg, sensor_host: sensor_pid}}
    end
  end

  defp maybe_start_sensor_host(template_id, opts) do
    if Keyword.get(opts, :start_sensor_host, false) do
      SensorHost.start_link(template_id: template_id)
      |> case do
        {:ok, pid} ->
          {:ok, pid}

        {:error, reason} ->
          {:error,
           Error.new(:sensor_host_start_failed, "failed to start sensor host", %{
             reason: inspect(reason)
           })}
      end
    else
      {:ok, nil}
    end
  end
end
