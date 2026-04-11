defmodule JidoBuilderRuntime.DynamicSensor do
  @moduledoc """
  Resolves sensor mounts from `templates_sensors` rows.

  Sensor rows must point to a known sensor slug from `Jido.Discovery`.
  """

  import Ecto.Query

  alias JidoBuilderCore.Repo
  alias JidoBuilderCore.Templates.TemplateSensor
  alias JidoBuilderRuntime.Error

  @type mount :: {module(), map()}

  @spec mounts_for_template(pos_integer()) :: {:ok, [mount()]} | {:error, Error.t()}
  def mounts_for_template(template_id) when is_integer(template_id) do
    TemplateSensor
    |> where([s], s.template_id == ^template_id and s.enabled == true)
    |> Repo.all()
    |> Enum.reduce_while({:ok, []}, fn row, {:ok, acc} ->
      case resolve_row(row) do
        {:ok, mount} -> {:cont, {:ok, [mount | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, mounts} -> {:ok, Enum.reverse(mounts)}
      error -> error
    end
  end

  @spec resolve_row(TemplateSensor.t()) :: {:ok, mount()} | {:error, Error.t()}
  def resolve_row(%TemplateSensor{module: slug, config: config, name: name}) do
    case Jido.Discovery.get_sensor_by_slug(slug) do
      %{module: module} when is_atom(module) ->
        {:ok, {module, Map.put(config || %{}, :name, name)}}

      _ ->
        {:error, Error.new(:unknown_sensor_slug, "unknown sensor slug", %{sensor_slug: slug})}
    end
  end
end
