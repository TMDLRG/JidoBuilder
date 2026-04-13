defmodule JidoBuilderRuntime.Factory.Versioning do
  @moduledoc """
  Template versioning for the Agent Factory.

  Manages config snapshots, version history, rollback, and diff
  between template versions.
  """

  @type version_entry :: %{
          version: pos_integer(),
          config_snapshot: map(),
          changelog: String.t(),
          created_at: DateTime.t()
        }

  @doc "Create a new version snapshot of a template config."
  @spec create_version(map(), String.t()) :: version_entry()
  def create_version(config, changelog \\ "") do
    %{
      version: System.unique_integer([:positive, :monotonic]),
      config_snapshot: deep_copy(config),
      changelog: changelog,
      created_at: DateTime.utc_now()
    }
  end

  @doc "Compute diff between two version snapshots."
  @spec diff(map(), map()) :: map()
  def diff(old_config, new_config) do
    added = Map.keys(new_config) -- Map.keys(old_config)
    removed = Map.keys(old_config) -- Map.keys(new_config)
    common = Map.keys(old_config) -- removed

    changed =
      Enum.filter(common, fn key ->
        Map.get(old_config, key) != Map.get(new_config, key)
      end)

    %{
      added: added,
      removed: removed,
      changed: changed,
      unchanged: common -- changed
    }
  end

  @doc "Apply a version snapshot to restore a config."
  @spec rollback(version_entry()) :: map()
  def rollback(%{config_snapshot: snapshot}), do: deep_copy(snapshot)

  @doc "Clone a template config with selective overrides."
  @spec clone(map(), map()) :: map()
  def clone(source_config, overrides \\ %{}) do
    deep_copy(source_config)
    |> Map.merge(overrides)
  end

  defp deep_copy(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, deep_copy(v)} end)
  end
  defp deep_copy(list) when is_list(list), do: Enum.map(list, &deep_copy/1)
  defp deep_copy(other), do: other
end
