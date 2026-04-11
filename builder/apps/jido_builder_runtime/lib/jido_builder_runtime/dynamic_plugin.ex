defmodule JidoBuilderRuntime.DynamicPlugin do
  @moduledoc """
  Resolves plugin mounts from `templates_plugins` rows.

  Plugin rows must point to a known plugin slug from `Jido.Discovery`.
  """

  import Ecto.Query

  alias JidoBuilderCore.Repo
  alias JidoBuilderCore.Templates.TemplatePlugin
  alias JidoBuilderRuntime.Error

  @type mount :: {module(), map()}

  @spec mounts_for_template(pos_integer()) :: {:ok, [mount()]} | {:error, Error.t()}
  def mounts_for_template(template_id) when is_integer(template_id) do
    TemplatePlugin
    |> where([p], p.template_id == ^template_id and p.enabled == true)
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

  @spec resolve_row(TemplatePlugin.t()) :: {:ok, mount()} | {:error, Error.t()}
  def resolve_row(%TemplatePlugin{module: slug, config: config, name: name}) do
    case Jido.Discovery.get_plugin_by_slug(slug) do
      %{module: module} when is_atom(module) ->
        {:ok, {module, Map.put(config || %{}, :name, name)}}

      _ ->
        {:error, Error.new(:unknown_plugin_slug, "unknown plugin slug", %{plugin_slug: slug})}
    end
  end
end
