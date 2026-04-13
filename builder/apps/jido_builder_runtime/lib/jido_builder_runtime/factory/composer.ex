defmodule JidoBuilderRuntime.Factory.Composer do
  @moduledoc """
  Template Composition Engine.

  Merges routes, state fields, and plugins from multiple templates into
  a single composed template definition. Handles conflict detection and
  deduplication of action routes.
  """

  @type template_def :: %{
          name: String.t(),
          routes: [map()],
          state_fields: [map()],
          plugins: [map()],
          config: map()
        }

  @doc """
  Compose multiple template definitions into one.

  Merges routes, state fields, and plugins. Detects and reports conflicts.
  """
  @spec compose([template_def()], keyword()) :: {:ok, template_def()} | {:error, term()}
  def compose(templates, opts \\ [])
  def compose([], _opts), do: {:error, "No templates to compose"}

  def compose(templates, opts) when is_list(templates) do
    name = Keyword.get(opts, :name, "composed_agent")

    # Collect all before dedup for conflict detection
    all_routes = Enum.flat_map(templates, fn t -> t[:routes] || [] end)
    all_fields = Enum.flat_map(templates, fn t -> t[:state_fields] || [] end)

    conflicts = detect_conflicts(all_routes, all_fields)

    merged_routes = merge_routes(templates)
    merged_fields = merge_state_fields(templates)
    merged_plugins = merge_plugins(templates)
    merged_config = merge_configs(templates)

    if length(conflicts) > 0 and not Keyword.get(opts, :force, false) do
      {:error, {:conflicts, conflicts}}
    else
      {:ok, %{
        name: name,
        routes: merged_routes,
        state_fields: merged_fields,
        plugins: merged_plugins,
        config: merged_config,
        source_templates: Enum.map(templates, & &1[:name] || "unnamed"),
        conflicts: conflicts
      }}
    end
  end

  @doc "Detect conflicts between template definitions."
  @spec detect_conflicts([map()], [map()]) :: [map()]
  def detect_conflicts(routes, state_fields) do
    route_conflicts = find_duplicate_signals(routes)
    field_conflicts = find_duplicate_fields(state_fields)
    route_conflicts ++ field_conflicts
  end

  # -- Private --

  defp merge_routes(templates) do
    templates
    |> Enum.flat_map(fn t -> t[:routes] || [] end)
    |> Enum.uniq_by(fn r -> {r[:signal], r[:action]} end)
  end

  defp merge_state_fields(templates) do
    templates
    |> Enum.flat_map(fn t -> t[:state_fields] || [] end)
    |> Enum.uniq_by(fn f -> f[:field_name] end)
  end

  defp merge_plugins(templates) do
    templates
    |> Enum.flat_map(fn t -> t[:plugins] || [] end)
    |> Enum.uniq_by(fn p -> p[:name] || p[:module] end)
  end

  defp merge_configs(templates) do
    templates
    |> Enum.map(fn t -> t[:config] || %{} end)
    |> Enum.reduce(%{}, &Map.merge(&2, &1))
  end

  defp find_duplicate_signals(routes) do
    routes
    |> Enum.group_by(fn r -> r[:signal] end)
    |> Enum.filter(fn {_signal, group} -> length(group) > 1 end)
    |> Enum.map(fn {signal, group} ->
      %{type: :route_conflict, signal: signal, count: length(group),
        actions: Enum.map(group, & &1[:action])}
    end)
  end

  defp find_duplicate_fields(fields) do
    fields
    |> Enum.group_by(fn f -> f[:field_name] end)
    |> Enum.filter(fn {_name, group} -> length(group) > 1 end)
    |> Enum.map(fn {name, group} ->
      types = Enum.map(group, & &1[:field_type]) |> Enum.uniq()
      if length(types) > 1 do
        %{type: :field_type_conflict, field: name, types: types}
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
end
